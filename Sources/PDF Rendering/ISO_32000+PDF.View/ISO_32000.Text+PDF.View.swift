//
//  PDF.Text+PDF.View.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

import Byte_Primitives
import Layout_Primitives
import PDF_Standard

extension ISO_32000.Text: PDF.View {

    public var body: Never {
        fatalError("PDF.Text is a leaf view")
    }

    public static func _render(_ text: Self, context: inout PDF.Context) {
        // Get font and size from text state, falling back to context defaults
        let font = text.state.font.flatMap { context.fonts[$0.name] } ?? context.style.font
        let fontSize = text.state.fontSize ?? context.style.fontSize

        if context.spacing.isHorizontal {
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
            maxWidth: context.layout.box.width
        )

        for line in lines {
            // Check for page break before each line
            context.page.ensure(height: context.style.line.height)

            // In top-left coordinates, context.layout.box.lly is the top of the line box.
            // PDF text is positioned at the baseline, so we offset down by the
            // ascender height (distance from baseline to top of tallest glyphs).
            let baselineY: PDF.UserSpace.Y =
                context.layout.box.lly + font.metrics.ascender(atSize: fontSize)

            // Emit bytes directly to content stream
            context.emit.text(
                line,
                at: PDF.UserSpace.Coordinate(x: context.layout.box.llx, y: baselineY),
                font: font,
                size: fontSize,
                color: context.style.color
            )

            context.advance.line()
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
        context.page.ensure(height: context.style.line.height)

        // Calculate text width (width table indexes by byte value — arithmetic domain)
        let textWidth = font.winAnsi.width(of: text.content.underlying, atSize: fontSize)

        // In top-left coordinates, context.layout.box.lly is the top of the line box.
        let baselineY = context.layout.box.lly + font.metrics.ascender(atSize: fontSize)

        // Emit text
        context.emit.text(
            text.content,
            at: PDF.UserSpace.Coordinate(x: context.layout.box.llx, y: baselineY),
            font: font,
            size: fontSize,
            color: context.style.color
        )

        // Advance X by text width and track Y for max height
        context.advance.x(textWidth)
        context.advance.line()
    }

    /// Wrap bytes to fit within max width
    ///
    /// Uses O(n) algorithm by tracking running line width instead of recalculating.
    private static func wrapBytes(
        _ bytes: [Byte],
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        maxWidth: PDF.UserSpace.Width
    ) -> [[Byte]] {
        guard !bytes.isEmpty else { return [[]] }

        // WinAnsi space byte for word boundaries (byte-domain).
        let spaceByte = Byte(UInt8.ascii.space)

        // Pre-calculate space width once (width table indexes by byte value — arithmetic).
        let spaceWidth = font.winAnsi.width(of: [.ascii.space], atSize: size)

        var lines: [[Byte]] = []
        var currentLine: [Byte] = []
        var currentLineWidth: PDF.UserSpace.Width = .zero
        var currentWord: [Byte] = []

        // Reserve capacity to reduce reallocations
        currentLine.reserveCapacity(256)
        currentWord.reserveCapacity(64)

        /// Process a completed word - add to current line or start new line
        func processWord() {
            guard !currentWord.isEmpty else { return }

            let wordWidth = font.winAnsi.width(of: currentWord.underlying, atSize: size)

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
                    currentLine.append(spaceByte)
                    currentLine.append(contentsOf: currentWord)
                    currentLineWidth = potentialWidth
                } else {
                    // Start new line - add trailing space to preserve word boundary.
                    // This ensures copy-paste from PDF viewers extracts proper spacing
                    // between the last word of this line and first word of next line.
                    currentLine.append(spaceByte)
                    lines.append(currentLine)
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            }
            currentWord = []
        }

        for byte in bytes {
            if byte == spaceByte {
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
