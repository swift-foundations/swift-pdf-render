// PDFText.swift

public import PDF_Standard

/// Text element with automatic line wrapping
public struct PDFText: PDFRenderable, Sendable {
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

    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        let effectiveFont = font ?? context.font
        let effectiveSize = fontSize ?? context.fontSize
        let effectiveColor = color ?? context.color

        // Word wrap the text
        let lines = wrapText(
            text,
            font: effectiveFont,
            size: effectiveSize,
            maxWidth: context.availableWidth
        )

        var operations: [PDF.Content] = []

        for line in lines {
            let content = PDF.Content.text(
                line,
                at: PDF.Point(x: context.x, y: context.y),
                font: effectiveFont,
                size: effectiveSize,
                color: effectiveColor
            )
            operations.append(content)
            context.advanceLine()
        }

        return PDF.Content(operations: operations.flatMap { $0.operations })
    }

    /// Wrap text to fit within max width
    private func wrapText(
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
                // First word on line
                if wordWidth > maxWidth {
                    // Word is too long, force it on its own line
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

