// PDF.Text.swift

public import PDF_Standard
public import Renderable

extension PDF {
    /// Text element with automatic line wrapping
    public struct Text: PDF.View, Sendable {
        public typealias Content = Never
        public typealias Context = PDF.Context
        public typealias Output = PDF.Render.Operation

        /// The text to render
        public var text: String

        /// Font override (uses context font if nil)
        public var font: PDF.Font?

        /// Font size override (uses context size if nil)
        public var fontSize: PDF.UserSpace.Unit?

        /// Color override (uses context color if nil)
        public var color: PDF.Color?

        /// Create a text element
        public init(
            _ text: String,
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Unit? = nil,
            color: PDF.Color? = nil
        ) {
            self.text = text
            self.font = font
            self.fontSize = fontSize
            self.color = color
        }

        public var body: Never {
            fatalError("PDF.Text is a leaf view")
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context
        ) where Buffer.Element == PDF.Render.Operation {
            let effectiveFont = view.font ?? context.font
            let effectiveSize = view.fontSize ?? context.fontSize
            let effectiveColor = view.color ?? context.color

            // Word wrap the text
            let lines = wrapText(
                view.text,
                font: effectiveFont,
                size: effectiveSize,
                maxWidth: context.availableWidth
            )

            for line in lines {
                // Check for page break before each line
                context.checkPageBreak(needing: PDF.UserSpace.Height(context.lineHeightPoints))

                // In top-left coordinates, context.y is the top of the line box.
                // PDF text is positioned at the baseline, so we offset down by the
                // ascender height (distance from baseline to top of tallest glyphs).
                let baselineY = PDF.UserSpace.Y(PDF.UserSpace.Unit(context.y.value) + effectiveFont.metrics.ascender(atSize: effectiveSize))

                let operation = PDF.Render.Operation.text(PDF.Render.TextOperation(
                    text: line,
                    position: PDF.UserSpace.Coordinate(x: context.x, y: baselineY),
                    font: effectiveFont,
                    size: effectiveSize,
                    color: effectiveColor
                ))

                // Add to context for proper pagination
                context.addOperation(operation)
                // Also add to buffer for callers that use it
                buffer.append(operation)

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
                    let potentialWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(lineWidth.value + spaceWidth.value + wordWidth.value))

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
}
