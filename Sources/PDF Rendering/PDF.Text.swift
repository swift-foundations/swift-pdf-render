// PDF.Text.swift

public import PDF_Standard

extension PDF {
    /// Text element with automatic line wrapping
    public struct Text: PDF.View, Sendable {
        public typealias Content = Never

        /// The text to render
        public var text: String

        /// Font override (uses context font if nil)
        public var font: PDF.Font?

        /// Font size override (uses context size if nil)
        public var fontSize: Double?

        /// Color override (uses context color if nil)
        public var color: PDF.Color?

        /// Create a text element
        public init(
            _ text: String,
            font: PDF.Font? = nil,
            fontSize: Double? = nil,
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

        public static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content {
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

            var operations: [PDF.Content.Operation] = []

            for line in lines {
                operations.append(.text(PDF.Content.Text.Operation(
                    text: line,
                    position: PDF.Point(x: context.x, y: context.y),
                    font: effectiveFont,
                    size: effectiveSize,
                    color: effectiveColor
                )))
                context.advanceLine()
            }

            return PDF.Content(operations: operations)
        }

        /// Wrap text to fit within max width
        private static func wrapText(
            _ text: String,
            font: PDF.Font,
            size: Double,
            maxWidth: Double
        ) -> [String] {
            let words = text.split(separator: " ", omittingEmptySubsequences: false)
            var lines: [String] = []
            var currentLine = ""
            let spaceWidth = font.stringWidth(" ", atSize: size)

            for word in words {
                let wordString = String(word)
                let wordWidth = font.stringWidth(wordString, atSize: size)

                if currentLine.isEmpty {
                    if wordWidth > maxWidth {
                        lines.append(wordString)
                    } else {
                        currentLine = wordString
                    }
                } else {
                    let lineWidth = font.stringWidth(currentLine, atSize: size)
                    let potentialWidth = lineWidth + spaceWidth + wordWidth

                    if potentialWidth <= maxWidth {
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
