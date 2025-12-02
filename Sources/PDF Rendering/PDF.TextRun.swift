// PDF.TextRun.swift

public import PDF_Standard

extension PDF {
    /// A styled text segment for inline text flow.
    ///
    /// TextRuns accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct TextRun: Sendable {
        /// The text content
        public let text: String

        /// Font for this text segment
        public let font: PDF.Font

        /// Font size in points
        public let fontSize: Double

        /// Text color
        public let color: PDF.Color

        /// Create a text run
        public init(
            text: String,
            font: PDF.Font,
            fontSize: Double,
            color: PDF.Color
        ) {
            self.text = text
            self.font = font
            self.fontSize = fontSize
            self.color = color
        }

        /// Render multiple text runs with proper line wrapping.
        ///
        /// This algorithm:
        /// 1. Tokenizes all runs into words with their styling
        /// 2. Builds lines by accumulating words until width exceeds available
        /// 3. Emits TextOperations with precise X positions for each styled segment
        public static func renderRuns(
            _ runs: [TextRun],
            context: inout PDF.Context
        ) -> PDF.Content {
            guard !runs.isEmpty else { return PDF.Content() }

            // Tokenize runs into styled words
            let tokens = tokenize(runs)
            guard !tokens.isEmpty else { return PDF.Content() }

            // Build lines from tokens
            let lines = buildLines(tokens: tokens, maxWidth: context.availableWidth)

            // Render lines
            var operations: [PDF.Operation] = []

            for line in lines {
                let lineOps = renderLine(line, context: &context)
                operations.append(contentsOf: lineOps)
                context.advanceLine()
            }

            return PDF.Content(operations: operations)
        }
    }
}

// MARK: - Tokenization

extension PDF.TextRun {
    /// A styled token (word or whitespace)
    struct Token: Sendable {
        enum Kind: Sendable {
            case word(String)
            case space
        }

        let kind: Kind
        let font: PDF.Font
        let fontSize: Double
        let color: PDF.Color

        var width: Double {
            switch kind {
            case .word(let text):
                return font.stringWidth(text, atSize: fontSize)
            case .space:
                return font.stringWidth(" ", atSize: fontSize)
            }
        }

        var text: String {
            switch kind {
            case .word(let text): return text
            case .space: return " "
            }
        }
    }

    /// Tokenize runs into styled words and spaces
    static func tokenize(_ runs: [PDF.TextRun]) -> [Token] {
        var tokens: [Token] = []

        for run in runs {
            // Handle empty text
            if run.text.isEmpty { continue }

            // Track if we're at the start of a word
            var currentWord = ""

            for char in run.text {
                if char == " " || char == "\t" || char == "\n" {
                    // Flush current word if any
                    if !currentWord.isEmpty {
                        tokens.append(Token(
                            kind: .word(currentWord),
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color
                        ))
                        currentWord = ""
                    }
                    // Add space token
                    tokens.append(Token(
                        kind: .space,
                        font: run.font,
                        fontSize: run.fontSize,
                        color: run.color
                    ))
                } else {
                    currentWord.append(char)
                }
            }

            // Flush remaining word
            if !currentWord.isEmpty {
                tokens.append(Token(
                    kind: .word(currentWord),
                    font: run.font,
                    fontSize: run.fontSize,
                    color: run.color
                ))
            }
        }

        return tokens
    }
}

// MARK: - Line Building

extension PDF.TextRun {
    /// A line of tokens
    struct Line: Sendable {
        var tokens: [Token]

        var isEmpty: Bool { tokens.isEmpty }

        var width: Double {
            tokens.reduce(0) { $0 + $1.width }
        }

        /// Tokens with trailing spaces removed
        var trimmedTokens: [Token] {
            var result = tokens
            while let last = result.last, case .space = last.kind {
                result.removeLast()
            }
            return result
        }
    }

    /// Build lines from tokens respecting max width
    static func buildLines(tokens: [Token], maxWidth: Double) -> [Line] {
        var lines: [Line] = []
        var currentLine = Line(tokens: [])
        var currentWidth: Double = 0

        for token in tokens {
            let tokenWidth = token.width

            switch token.kind {
            case .word:
                if currentLine.isEmpty {
                    // First word on line - always add it
                    currentLine.tokens.append(token)
                    currentWidth = tokenWidth
                } else if currentWidth + tokenWidth <= maxWidth {
                    // Word fits on current line
                    currentLine.tokens.append(token)
                    currentWidth += tokenWidth
                } else {
                    // Word doesn't fit - start new line
                    lines.append(currentLine)
                    currentLine = Line(tokens: [token])
                    currentWidth = tokenWidth
                }

            case .space:
                if !currentLine.isEmpty {
                    // Only add space if we have content and it might fit
                    if currentWidth + tokenWidth <= maxWidth {
                        currentLine.tokens.append(token)
                        currentWidth += tokenWidth
                    }
                    // Otherwise skip the space (will start new line on next word)
                }
            }
        }

        // Add remaining line if not empty
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }
}

// MARK: - Line Rendering

extension PDF.TextRun {
    /// Render a single line of tokens
    static func renderLine(_ line: Line, context: inout PDF.Context) -> [PDF.Operation] {
        var operations: [PDF.Operation] = []
        var currentX = context.x

        // Use trimmed tokens to avoid trailing spaces
        let tokens = line.trimmedTokens

        // Group consecutive tokens with same styling
        var currentSegment = ""
        var currentFont: PDF.Font?
        var currentSize: Double?
        var currentColor: PDF.Color?
        var segmentStartX = currentX

        func flushSegment() {
            guard !currentSegment.isEmpty,
                  let font = currentFont,
                  let size = currentSize,
                  let color = currentColor else { return }

            operations.append(.text(PDF.TextOperation(
                text: currentSegment,
                position: PDF.Point(x: segmentStartX, y: context.y),
                font: font,
                size: size,
                color: color
            )))
            currentSegment = ""
        }

        for token in tokens {
            let sameStyle = token.font == currentFont &&
                           token.fontSize == currentSize &&
                           token.color == currentColor

            if sameStyle {
                // Same style - append to current segment
                currentSegment += token.text
            } else {
                // Style changed - flush previous segment
                flushSegment()

                // Start new segment
                segmentStartX = currentX
                currentSegment = token.text
                currentFont = token.font
                currentSize = token.fontSize
                currentColor = token.color
            }

            currentX += token.width
        }

        // Flush remaining segment
        flushSegment()

        return operations
    }
}
