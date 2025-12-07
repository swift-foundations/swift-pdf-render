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
        
        // Word wrap the text
        let lines = wrapText(
            view.text,
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
            
            // Emit text directly to content stream
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
    
    /// Wrap text to fit within max width
    private static func wrapText(
        _ text: String,
        font: PDF.Font,
        size: PDF.UserSpace.Unit,
        maxWidth: PDF.UserSpace.Width
    ) -> [String] {
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var lines: [String] = []
        var currentLine = ""
        let spaceWidth = PDF.UserSpace.Width(font.stringWidth(" ", atSize: size))
        
        for word in words {
            let wordString = String(word)
            let wordWidth = PDF.UserSpace.Width(font.stringWidth(wordString, atSize: size))
            
            if currentLine.isEmpty {
                if wordWidth.value > maxWidth.value {
                    lines.append(wordString)
                } else {
                    currentLine = wordString
                }
            } else {
                let lineWidth = PDF.UserSpace.Width(font.stringWidth(currentLine, atSize: size))
                let potentialWidth = PDF.UserSpace.Width(lineWidth.value + spaceWidth.value + wordWidth.value)
                
                if potentialWidth.value <= maxWidth.value {
                    currentLine += " " + wordString
                } else {
                    lines.append(currentLine)
                    currentLine = wordString
                }
            }
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines.isEmpty ? [""] : lines
    }
}
