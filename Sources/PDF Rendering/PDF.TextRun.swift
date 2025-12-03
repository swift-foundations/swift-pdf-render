// PDF.TextRun.swift

public import PDF_Standard

extension PDF {
    /// Text decoration options
    public enum TextDecoration: String, Sendable {
        case none
        case underline
        case lineThrough
    }

    /// A styled text segment for inline text flow.
    ///
    /// TextRuns accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct TextRun: Sendable {
        /// The text content (sanitized for PDF encoding)
        public let text: String

        /// Font for this text segment
        public let font: PDF.Font

        /// Font size in points
        public let fontSize: Double

        /// Text color
        public let color: PDF.Color

        /// Text decoration (underline, strikethrough, etc.)
        public let textDecoration: TextDecoration

        /// Background color for highlighting
        public let backgroundColor: PDF.Color?

        /// Vertical offset for subscript/superscript (positive = up, negative = down)
        public let verticalOffset: Double

        /// Optional link URL (makes this text a clickable link)
        public let linkURL: String?

        /// Create a text run
        public init(
            text: String,
            font: PDF.Font,
            fontSize: Double,
            color: PDF.Color,
            textDecoration: TextDecoration = .none,
            backgroundColor: PDF.Color? = nil,
            verticalOffset: Double = 0,
            linkURL: String? = nil
        ) {
            // Sanitize text to replace unsupported Unicode characters
            self.text = Self.sanitizeForPDF(text)
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.backgroundColor = backgroundColor
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
        }

        /// Sanitize text for PDF Standard 14 fonts (WinAnsiEncoding).
        ///
        /// Replaces Unicode characters that aren't in WinAnsiEncoding
        /// with ASCII equivalents.
        private static func sanitizeForPDF(_ text: String) -> String {
            var result = ""
            result.reserveCapacity(text.count)

            for scalar in text.unicodeScalars {
                switch scalar.value {
                // Em-dash (—) → --
                case 0x2014:
                    result += "--"
                // En-dash (–) → -
                case 0x2013:
                    result += "-"
                // Left double quote (") → "
                case 0x201C:
                    result += "\""
                // Right double quote (") → "
                case 0x201D:
                    result += "\""
                // Left single quote (') → '
                case 0x2018:
                    result += "'"
                // Right single quote (') → '
                case 0x2019:
                    result += "'"
                // Horizontal ellipsis (…) → ...
                case 0x2026:
                    result += "..."
                // Bullet (•) → hyphen for now (encoding issues with special chars)
                case 0x2022:
                    result.append("-")
                // Non-breaking space → regular space
                case 0x00A0:
                    result += " "
                // Minus sign (−) → -
                case 0x2212:
                    result += "-"
                // Multiplication sign (×) → x
                case 0x00D7:
                    result += "x"
                // Division sign (÷) → /
                case 0x00F7:
                    result += "/"
                // Copyright sign (©) → (c) for safety
                case 0x00A9:
                    result += "(c)"
                // Trademark (™) → (TM)
                case 0x2122:
                    result += "(TM)"
                // Registered trademark (®) → (R) for safety
                case 0x00AE:
                    result += "(R)"
                // Check if in WinAnsiEncoding range (Basic Latin + Latin-1 Supplement)
                case 0x0020...0x007E, 0x00A1...0x00FF:
                    result.append(Character(scalar))
                // Other characters → ?
                default:
                    // For characters outside WinAnsiEncoding, use replacement
                    if scalar.value < 0x0100 {
                        result.append(Character(scalar))
                    } else {
                        result += "?"
                    }
                }
            }

            return result
        }

        /// Render multiple text runs with proper line wrapping.
        ///
        /// This algorithm:
        /// 1. Tokenizes all runs into words with their styling
        /// 2. Builds lines by accumulating words until width exceeds available
        /// 3. Emits TextOperations with precise X positions for each styled segment
        /// 4. Handles page breaks automatically when lines exceed page boundary
        public static func renderRuns(
            _ runs: [TextRun],
            context: inout PDF.Context
        ) -> PDF.Content {
            guard !runs.isEmpty else { return PDF.Content() }

            // Tokenize runs into styled words (preserve whitespace for preformatted text)
            let tokens = tokenize(runs, preserveWhitespace: context.preserveWhitespace)
            guard !tokens.isEmpty else { return PDF.Content() }

            // Build lines from tokens
            let lines = buildLines(tokens: tokens, maxWidth: context.availableWidth)

            // Render lines with pagination support
            for line in lines {
                // Check if this line would exceed the page
                let lineHeight = context.lineHeightPoints
                context.checkPageBreak(needing: lineHeight)

                // Render the line and add operations to context
                let lineOps = renderLine(line, context: &context)
                context.addOperations(lineOps)
                context.advanceLine()
            }

            // Return empty - operations are stored in context for pagination
            return PDF.Content()
        }
    }
}

// MARK: - Tokenization

extension PDF.TextRun {
    /// A styled token (word, whitespace, or line break)
    struct Token: Sendable {
        enum Kind: Sendable {
            case word(String)
            case space
            case lineBreak  // Explicit line break for preformatted text
        }

        let kind: Kind
        let font: PDF.Font
        let fontSize: Double
        let color: PDF.Color
        let textDecoration: PDF.TextDecoration
        let backgroundColor: PDF.Color?
        let verticalOffset: Double
        let linkURL: String?

        var width: Double {
            switch kind {
            case .word(let text):
                return font.stringWidth(text, atSize: fontSize)
            case .space:
                return font.stringWidth(" ", atSize: fontSize)
            case .lineBreak:
                return 0  // Line breaks have no width
            }
        }

        var text: String {
            switch kind {
            case .word(let text): return text
            case .space: return " "
            case .lineBreak: return ""
            }
        }
    }

    /// Tokenize runs into styled words and spaces
    ///
    /// - Parameters:
    ///   - runs: Text runs to tokenize
    ///   - preserveWhitespace: If true, preserves newlines as explicit line breaks
    ///     and doesn't collapse multiple spaces. Used for `<pre>` blocks.
    static func tokenize(_ runs: [PDF.TextRun], preserveWhitespace: Bool = false) -> [Token] {
        var tokens: [Token] = []

        for run in runs {
            // Handle empty text
            if run.text.isEmpty { continue }

            // Track current word being built
            var currentWord = ""

            for char in run.text {
                if preserveWhitespace {
                    // Preformatted mode: preserve structure
                    if char == "\n" {
                        // Flush current word if any
                        if !currentWord.isEmpty {
                            tokens.append(Token(
                                kind: .word(currentWord),
                                font: run.font,
                                fontSize: run.fontSize,
                                color: run.color,
                                textDecoration: run.textDecoration,
                                backgroundColor: run.backgroundColor,
                                verticalOffset: run.verticalOffset,
                                linkURL: run.linkURL
                            ))
                            currentWord = ""
                        }
                        // Add explicit line break
                        tokens.append(Token(
                            kind: .lineBreak,
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            backgroundColor: run.backgroundColor,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL
                        ))
                    } else if char == " " || char == "\t" {
                        // In preformatted mode, each space/tab is its own token
                        if !currentWord.isEmpty {
                            tokens.append(Token(
                                kind: .word(currentWord),
                                font: run.font,
                                fontSize: run.fontSize,
                                color: run.color,
                                textDecoration: run.textDecoration,
                                backgroundColor: run.backgroundColor,
                                verticalOffset: run.verticalOffset,
                                linkURL: run.linkURL
                            ))
                            currentWord = ""
                        }
                        // Use tab as 4 spaces worth of width
                        let spaceText = char == "\t" ? "    " : " "
                        tokens.append(Token(
                            kind: .word(spaceText),
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            backgroundColor: run.backgroundColor,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL
                        ))
                    } else {
                        currentWord.append(char)
                    }
                } else {
                    // Normal mode: collapse whitespace
                    if char == " " || char == "\t" || char == "\n" {
                        // Flush current word if any
                        if !currentWord.isEmpty {
                            tokens.append(Token(
                                kind: .word(currentWord),
                                font: run.font,
                                fontSize: run.fontSize,
                                color: run.color,
                                textDecoration: run.textDecoration,
                                backgroundColor: run.backgroundColor,
                                verticalOffset: run.verticalOffset,
                                linkURL: run.linkURL
                            ))
                            currentWord = ""
                        }
                        // Add space token
                        tokens.append(Token(
                            kind: .space,
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            backgroundColor: run.backgroundColor,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL
                        ))
                    } else {
                        currentWord.append(char)
                    }
                }
            }

            // Flush remaining word
            if !currentWord.isEmpty {
                tokens.append(Token(
                    kind: .word(currentWord),
                    font: run.font,
                    fontSize: run.fontSize,
                    color: run.color,
                    textDecoration: run.textDecoration,
                    backgroundColor: run.backgroundColor,
                    verticalOffset: run.verticalOffset,
                    linkURL: run.linkURL
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

            case .lineBreak:
                // Explicit line break - finish current line and start new one
                // Add current line even if empty (to preserve blank lines in preformatted text)
                lines.append(currentLine)
                currentLine = Line(tokens: [])
                currentWidth = 0
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
    static func renderLine(_ line: Line, context: inout PDF.Context) -> [PDF.Render.Operation] {
        var operations: [PDF.Render.Operation] = []
        var currentX = context.x

        // Use trimmed tokens to avoid trailing spaces
        let tokens = line.trimmedTokens

        // Group consecutive tokens with same styling
        var currentSegment = ""
        var currentFont: PDF.Font?
        var currentSize: Double?
        var currentColor: PDF.Color?
        var currentDecoration: PDF.TextDecoration?
        var currentBackground: PDF.Color?
        var currentVerticalOffset: Double = 0
        var currentLinkURL: String? = nil
        var segmentStartX = currentX

        func flushSegment() {
            guard !currentSegment.isEmpty,
                  let font = currentFont,
                  let size = currentSize,
                  let color = currentColor else { return }

            let segmentWidth = font.stringWidth(currentSegment, atSize: size)
            // Apply vertical offset (negative moves up in top-down coordinates)
            let textY = context.y - currentVerticalOffset

            // Draw background first if present
            // In top-down coords: textY is baseline, text extends UP (smaller Y)
            // Need origin above the ascenders, height to cover down past descenders
            if let bgColor = currentBackground {
                let bgRect = PDF.Rect(
                    origin: PDF.Point(x: segmentStartX, y: textY - size * 0.85),
                    size: PDF.Size(width: segmentWidth, height: size * 1.15)
                )
                operations.append(.graphics(.rectangle(
                    bgRect,
                    fill: bgColor,
                    stroke: nil,
                    strokeWidth: 0
                )))
            }

            // Draw text with vertical offset applied
            operations.append(.text(PDF.Render.TextOperation(
                text: currentSegment,
                position: PDF.Point(x: segmentStartX, y: textY),
                font: font,
                size: size,
                color: color
            )))

            // Draw text decoration
            // Note: In top-down coordinates, +Y is down, -Y is up
            // Baseline is at textY (context.y with vertical offset applied)
            if let decoration = currentDecoration, decoration != .none {
                let lineY: Double
                switch decoration {
                case .underline:
                    lineY = textY + size * 0.15  // Below baseline (positive = down)
                case .lineThrough:
                    lineY = textY - size * 0.3   // Through middle of text (negative = up)
                case .none:
                    lineY = 0  // Never reached
                }

                let startPoint = PDF.Point(x: segmentStartX, y: lineY)
                let endPoint = PDF.Point(x: segmentStartX + segmentWidth, y: lineY)
                let lineWidth = max(0.5, size * 0.05)  // Line thickness proportional to font

                operations.append(.graphics(.line(
                    from: startPoint,
                    to: endPoint,
                    color: color,
                    width: lineWidth
                )))
            }

            // Add link annotation if this segment has a URL
            if let url = currentLinkURL {
                let linkRect = PDF.Rect(
                    origin: PDF.Point(x: segmentStartX, y: textY - size * 0.85),
                    size: PDF.Size(width: segmentWidth, height: size * 1.15)
                )
                context.addLinkAnnotation(rect: linkRect, uri: url)
            }

            currentSegment = ""
        }

        for token in tokens {
            let sameStyle = token.font == currentFont &&
                           token.fontSize == currentSize &&
                           token.color == currentColor &&
                           token.textDecoration == currentDecoration &&
                           token.backgroundColor == currentBackground &&
                           token.verticalOffset == currentVerticalOffset &&
                           token.linkURL == currentLinkURL

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
                currentDecoration = token.textDecoration
                currentBackground = token.backgroundColor
                currentVerticalOffset = token.verticalOffset
                currentLinkURL = token.linkURL
            }

            currentX += token.width
        }

        // Flush remaining segment
        flushSegment()

        return operations
    }
}
