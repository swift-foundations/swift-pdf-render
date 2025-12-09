//
//  PDF.Text+PDF.View.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

import PDF_Standard

extension PDF.Text: PDF.View {

    public var body: Never {
        fatalError("PDF.Text is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Resolve style: view's partial style combined with context's resolved style
        let effectiveStyle = PDF.Context.Style(context.style).combined(with: view.style).resolved()
        let effectiveFont = effectiveStyle.font
        let effectiveSize = effectiveStyle.fontSize
        let effectiveColor = effectiveStyle.color

        // Encode text to WinAnsi bytes at the boundary
        let bytes = [UInt8](winAnsi: view.text, withFallback: true)

        // Word wrap the bytes
        let lines = wrapBytes(
            bytes,
            font: effectiveFont,
            size: effectiveSize,
            maxWidth: context.layoutBox.width
        )

        for line in lines {
            // Check for page break before each line
            context.checkPageBreak(needing: context.style.lineHeightPoints)

            // In top-left coordinates, context.layoutBox.lly is the top of the line box.
            // PDF text is positioned at the baseline, so we offset down by the
            // ascender height (distance from baseline to top of tallest glyphs).
            let baselineY = PDF.UserSpace.Y(context.layoutBox.lly.value + effectiveFont.metrics.ascender(atSize: effectiveSize))

            // Emit bytes directly to content stream
            context.emitText(
                line,
                at: PDF.UserSpace.Coordinate(x: context.layoutBox.llx, y: baselineY),
                font: effectiveFont,
                size: effectiveSize,
                color: effectiveColor
            )

            context.advanceLine()
        }
    }

    /// Wrap bytes to fit within max width
    private static func wrapBytes(
        _ bytes: [UInt8],
        font: PDF.Font,
        size: PDF.UserSpace.Unit,
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
                if wordWidth > maxWidth.value {
                    lines.append(word)
                } else {
                    currentLine = word
                }
            } else {
                let lineWidth = font.winAnsi.width(of: currentLine, atSize: size)
                let potentialWidth = lineWidth + spaceWidth + wordWidth

                if potentialWidth <= maxWidth.value {
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
