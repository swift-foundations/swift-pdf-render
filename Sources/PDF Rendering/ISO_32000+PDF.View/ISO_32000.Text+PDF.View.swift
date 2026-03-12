//
//  PDF.Text+PDF.View.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

import Layout_Primitives
import PDF_Standard

extension ISO_32000.Text: PDF.View {

    public var body: Never {
        fatalError("PDF.Text is a leaf view")
    }

    public static func _render(_ text: Self, context: inout PDF.Context) {
        // Get font and size from text state, falling back to context defaults
        let font = text.state.font.flatMap { context.fontRegistry[$0.name] } ?? context.style.font
        let fontSize = text.state.fontSize ?? context.style.fontSize

        if context.isHorizontalLayout {
            _renderHorizontal(text, font: font, fontSize: fontSize, context: &context)
        } else {
            _renderVertical(text, font: font, fontSize: fontSize, context: &context)
        }
    }

    private static func _renderVertical(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {
        // Word wrap the bytes
        let lines = wrapBytes(
            text.content,
            font: font,
            size: fontSize,
            maxWidth: context.layoutBox.width
        )

        for line in lines {
            // Check for page break before each line
            context.checkPageBreak(needing: context.style.line.height)

            // In top-left coordinates, context.layoutBox.lly is the top of the line box.
            // PDF text is positioned at the baseline, so we offset down by the
            // ascender height (distance from baseline to top of tallest glyphs).
            let baselineY: PDF.UserSpace.Y =
                context.layoutBox.lly + font.metrics.ascender(atSize: fontSize)

            // Emit bytes directly to content stream
            context.emitText(
                line,
                at: PDF.UserSpace.Coordinate(x: context.layoutBox.llx, y: baselineY),
                font: font,
                size: fontSize,
                color: context.style.color
            )

            context.advanceLine()
        }
    }

    private static func _renderHorizontal(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {
        // In horizontal layout, render text on a single line without wrapping
        // and advance X by the text width

        // Check for page break
        context.checkPageBreak(needing: context.style.line.height)

        // Calculate text width
        let textWidth = font.winAnsi.width(of: text.content, atSize: fontSize)

        // In top-left coordinates, context.layoutBox.lly is the top of the line box.
        let baselineY = context.layoutBox.lly + font.metrics.ascender(atSize: fontSize)

        // Emit text
        context.emitText(
            text.content,
            at: PDF.UserSpace.Coordinate(x: context.layoutBox.llx, y: baselineY),
            font: font,
            size: fontSize,
            color: context.style.color
        )

        // Advance X by text width and track Y for max height
        context.advanceX(textWidth)
        context.advanceLine()
    }

    /// Wrap bytes to fit within max width
    ///
    /// Uses O(n) algorithm by tracking running line width instead of recalculating.
    private static func wrapBytes(
        _ bytes: [UInt8],
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        maxWidth: PDF.UserSpace.Width
    ) -> [[UInt8]] {
        guard !bytes.isEmpty else { return [[]] }

        // Pre-calculate space width once
        let spaceWidth = font.winAnsi.width(of: [.ascii.space], atSize: size)

        var lines: [[UInt8]] = []
        var currentLine: [UInt8] = []
        var currentLineWidth: PDF.UserSpace.Width = .zero
        var currentWord: [UInt8] = []

        // Reserve capacity to reduce reallocations
        currentLine.reserveCapacity(256)
        currentWord.reserveCapacity(64)

        /// Process a completed word - add to current line or start new line
        func processWord() {
            guard !currentWord.isEmpty else { return }

            let wordWidth = font.winAnsi.width(of: currentWord, atSize: size)

            if currentLine.isEmpty {
                // First word on line
                if wordWidth > maxWidth {
                    // Word too long - put on its own line
                    lines.append(currentWord)
                } else {
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            } else {
                // Check if word fits on current line (O(1) - no line recalculation!)
                let potentialWidth = currentLineWidth + spaceWidth + wordWidth
                if potentialWidth <= maxWidth {
                    currentLine.append(.ascii.space)
                    currentLine.append(contentsOf: currentWord)
                    currentLineWidth = potentialWidth
                } else {
                    // Start new line - add trailing space to preserve word boundary.
                    // This ensures copy-paste from PDF viewers extracts proper spacing
                    // between the last word of this line and first word of next line.
                    currentLine.append(.ascii.space)
                    lines.append(currentLine)
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            }
            currentWord = []
        }

        for byte in bytes {
            if byte == .ascii.space {
                processWord()
            } else {
                currentWord.append(byte)
            }
        }

        // Handle last word
        processWord()

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }
}
