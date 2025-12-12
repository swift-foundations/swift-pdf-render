//
//  PDF.Text+PDF.View.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

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
            context.checkPageBreak(needing: context.style.lineHeightPoints)

            // In top-left coordinates, context.layoutBox.lly is the top of the line box.
            // PDF text is positioned at the baseline, so we offset down by the
            // ascender height (distance from baseline to top of tallest glyphs).
            let baselineY: PDF.UserSpace.Y = context.layoutBox.lly + font.metrics.ascender(atSize: fontSize)

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

    private static func _renderHorizontal(_ text: Self, font: PDF.Font, fontSize: PDF.UserSpace.Size<1>, context: inout PDF.Context) {
        // In horizontal layout, render text on a single line without wrapping
        // and advance X by the text width

        // Check for page break
        context.checkPageBreak(needing: context.style.lineHeightPoints)

        // Calculate text width
        let textWidth = font.winAnsi.width(of: text.content, atSize: fontSize)

        // In top-left coordinates, context.layoutBox.lly is the top of the line box.
        let baselineY = PDF.UserSpace.Y(context.layoutBox.lly.value + font.metrics.ascender(atSize: fontSize).value)

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
    private static func wrapBytes(
        _ bytes: [UInt8],
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        maxWidth: PDF.UserSpace.Width
    ) -> [[UInt8]] {
        // Split bytes on spaces
        var words: [[UInt8]] = []
        var currentWord: [UInt8] = []

        for byte in bytes {
            if byte == .ascii.space {
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    currentWord = []
                }
                // Add empty word for consecutive spaces
                words.append([])
            } else {
                currentWord.append(byte)
            }
        }
        if !currentWord.isEmpty {
            words.append(currentWord)
        }

        var lines: [[UInt8]] = []
        var currentLine: [UInt8] = []
        let spaceWidth = font.winAnsi.width(of: [.ascii.space], atSize: size)

        for word in words {
            let wordWidth = font.winAnsi.width(of: word, atSize: size)

            if currentLine.isEmpty {
                if wordWidth > maxWidth {
                    lines.append(word)
                } else {
                    currentLine = word
                }
            } else {
                let lineWidth = font.winAnsi.width(of: currentLine, atSize: size)
                let potentialWidth = lineWidth + spaceWidth + wordWidth

                if potentialWidth <= maxWidth {
                    currentLine.append(.ascii.space)
                    currentLine.append(contentsOf: word)
                } else {
                    lines.append(currentLine)
                    currentLine = word
                }
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }
}
