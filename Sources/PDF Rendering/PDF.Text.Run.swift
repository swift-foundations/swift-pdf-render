// PDF.Text.Run.swift

public import PDF_Standard

extension PDF.Text {
    /// A styled text segment for inline text flow.
    ///
    /// Text.Runs accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct Run: Sendable {
        /// The text content (sanitized for PDF encoding)
        public let text: String
        
        /// Font for this text segment
        public let font: PDF.Font
        
        /// Font size in points
        public let fontSize: PDF.UserSpace.Unit
        
        /// Text color
        public let color: PDF.Color
        
        /// Text decoration (underline, strikethrough, etc.)
        public let textDecoration: PDF.TextMarkup?
        
        
        /// done through
        //        /// Background color for highlighting
        //        public let backgroundColor: PDF.Color?
        
        /// Vertical offset for subscript/superscript (positive = up, negative = down)
        public let verticalOffset: PDF.UserSpace.Unit
        
        /// Optional link URL (makes this text a clickable link)
        public let linkURL: String?
        
        /// Create a text run
        public init(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Unit,
            color: PDF.Color,
            textDecoration: PDF.TextMarkup? = .none,
            backgroundColor: PDF.Color? = nil,
            verticalOffset: PDF.UserSpace.Unit = 0,
            linkURL: String? = nil
        ) {
            // Store text as-is; WinAnsiEncoding will be applied during PDF serialization
            self.text = text
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
        }
        
        /// Render multiple text runs with proper line wrapping.
        ///
        /// This algorithm:
        /// 1. Tokenizes all runs into words with their styling
        /// 2. Builds lines by accumulating words until width exceeds available
        /// 3. Emits content directly to context's content stream
        /// 4. Handles page breaks automatically when lines exceed page boundary
        public static func renderRuns(
            _ runs: [PDF.Text.Run],
            context: inout PDF.Context
        ) {
            guard !runs.isEmpty else { return }

            // Tokenize runs into styled words (preserve whitespace for preformatted text)
            let tokens = tokenize(runs, preserveWhitespace: context.preserveWhitespace)
            guard !tokens.isEmpty else { return }

            // Build lines from tokens
            let lines = buildLines(tokens: tokens, maxWidth: context.layoutBox.width)

            // Render lines with pagination support
            var isFirstLine = true
            for line in lines {
                // Check if this line would exceed the page
                let lineHeight = context.style.lineHeightPoints
                context.checkPageBreak(needing: lineHeight)

                // Emit pending list marker on the first line
                if isFirstLine, let pending = context.pendingListMarker {
                    // Calculate baseline Y for the marker (same as text line)
                    let baseFont = context.style.font ?? .helvetica
                    let baseFontSize = context.style.fontSize ?? 12
                    let baselineY = PDF.UserSpace.Y(
                        context.layoutBox.lly.value +
                        baseFont.metrics.ascender(atSize: baseFontSize)
                    )

                    context.emitText(
                        pending.marker,
                        at: PDF.UserSpace.Coordinate(x: pending.x, y: baselineY),
                        font: context.style.font ?? .helvetica,
                        size: context.style.fontSize ?? 12,
                        color: context.style.color
                    )
                    context.pendingListMarker = nil
                    isFirstLine = false
                }

                // Render the line directly to context
                renderLine(line, context: &context)
                context.advanceLine()
            }
        }
    }
}

// MARK: - Tokenization

extension PDF.Text.Run {
    /// A styled token (word, whitespace, or line break)
    struct Token: Sendable {
        enum Kind: Sendable {
            case word(String)
            case space
            case lineBreak  // Explicit line break for preformatted text
        }
        
        let kind: Kind
        let font: PDF.Font
        let fontSize: PDF.UserSpace.Unit
        let color: PDF.Color
        let textDecoration: PDF.TextMarkup?
        let verticalOffset: PDF.UserSpace.Unit
        let linkURL: String?
        
        var width: PDF.UserSpace.Width {
            switch kind {
            case .word(let text):
                return PDF.UserSpace.Width(font.stringWidth(text, atSize: fontSize))
            case .space:
                return PDF.UserSpace.Width(font.stringWidth(" ", atSize: fontSize))
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
    static func tokenize(_ runs: [PDF.Text.Run], preserveWhitespace: Bool = false) -> [Token] {
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
                    verticalOffset: run.verticalOffset,
                    linkURL: run.linkURL
                ))
            }
        }
        
        return tokens
    }
}

// MARK: - Line Building

extension PDF.Text.Run {
    /// A line of tokens
    struct Line: Sendable {
        var tokens: [Token]
        
        var isEmpty: Bool { tokens.isEmpty }
        
        var width: PDF.UserSpace.Width {
            PDF.UserSpace.Width(PDF.UserSpace.Unit(tokens.reduce(0.0) { $0 + $1.width.value }))
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
    static func buildLines(tokens: [Token], maxWidth: PDF.UserSpace.Width) -> [Line] {
        var lines: [Line] = []
        var currentLine = Line(tokens: [])
        var currentWidth: PDF.UserSpace.Width = 0
        
        for token in tokens {
            let tokenWidth = token.width
            
            switch token.kind {
            case .word:
                if currentLine.isEmpty {
                    // First word on line - always add it
                    currentLine.tokens.append(token)
                    currentWidth = tokenWidth
                } else if currentWidth.value + tokenWidth.value <= maxWidth.value {
                    // Word fits on current line
                    currentLine.tokens.append(token)
                    currentWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(currentWidth.value + tokenWidth.value))
                } else {
                    // Word doesn't fit - start new line
                    lines.append(currentLine)
                    currentLine = Line(tokens: [token])
                    currentWidth = tokenWidth
                }
                
            case .space:
                if !currentLine.isEmpty {
                    // Only add space if we have content and it might fit
                    if currentWidth.value + tokenWidth.value <= maxWidth.value {
                        currentLine.tokens.append(token)
                        currentWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(currentWidth.value + tokenWidth.value))
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

extension PDF.Text.Run {
    /// Render a single line of tokens directly to context.
    static func renderLine(_ line: Line, context: inout PDF.Context) {
        var currentX = context.layoutBox.llx

        // Use trimmed tokens to avoid trailing spaces
        let tokens = line.trimmedTokens

        // Calculate line baseline from context's base style (not per-segment font)
        // This ensures consistent baseline alignment across different fonts (e.g., Helvetica and Courier)
        let baseFont = context.style.font ?? .helvetica
        let baseFontSize = context.style.fontSize ?? 12
        let lineBaselineY = PDF.UserSpace.Y(PDF.UserSpace.Unit(context.layoutBox.lly.value) + baseFont.metrics.ascender(atSize: baseFontSize))

        // Group consecutive tokens with same styling
        var currentSegment = ""
        var currentFont: PDF.Font?
        var currentSize: PDF.UserSpace.Unit?
        var currentColor: PDF.Color?
        var currentDecoration: PDF.TextMarkup?
        var currentVerticalOffset: PDF.UserSpace.Unit = 0
        var currentLinkURL: String? = nil
        var segmentStartX = currentX

        func flushSegment() {
            guard !currentSegment.isEmpty,
                  let font = currentFont,
                  let size = currentSize,
                  let color = currentColor else { return }

            let segmentWidth = PDF.UserSpace.Width(font.stringWidth(currentSegment, atSize: size))
            // Use the line's consistent baseline, adjusted for vertical offset (sub/superscript)
            let textY = PDF.UserSpace.Y(PDF.UserSpace.Unit(lineBaselineY.value) - currentVerticalOffset)

            // Draw highlight background BEFORE text (so text appears on top)
            if case .highlight(let highlightColor) = currentDecoration {
                let bgRect = PDF.UserSpace.Rectangle(
                    x: segmentStartX,
                    y: PDF.UserSpace.Y(textY.value - size.value * 0.85),
                    width: segmentWidth,
                    height: PDF.UserSpace.Height(size.value * 1.15)
                )
                context.emitRectangle(bgRect, fill: highlightColor, stroke: nil)
            }

            // Emit text directly to context
            context.emitText(
                currentSegment,
                at: PDF.UserSpace.Coordinate(x: segmentStartX, y: textY),
                font: font,
                size: size,
                color: color
            )

            // Draw text decoration if present (underline, strikethrough)
            if let decoration = currentDecoration {
                let lineY: PDF.UserSpace.Y
                switch decoration {
                case .underline:
                    lineY = PDF.UserSpace.Y(PDF.UserSpace.Unit(textY.value + size.value * 0.15))  // Below baseline (positive = down)
                case .strikeout:
                    // Position at half the x-height (middle of lowercase letters)
                    let xHeightHalf = font.metrics.xHeight(atSize: size).value / 2.0
                    lineY = PDF.UserSpace.Y(textY.value - .init(xHeightHalf))
                case .highlight:
                    return  // Already drawn above, no line needed
                case .jagged:
                    fatalError("unimplemented")
                }

                let startPoint = PDF.UserSpace.Coordinate(x: segmentStartX, y: lineY)
                let endPoint = PDF.UserSpace.Coordinate(x: PDF.UserSpace.X(PDF.UserSpace.Unit(segmentStartX.value + segmentWidth.value)), y: lineY)
                // WebKit uses approximately 1px line thickness, which at 72dpi is about 0.07-0.08 of font size
                let lineWidth = PDF.UserSpace.Width(PDF.UserSpace.Unit(size.value * 0.07))
                let minLineWidth: PDF.UserSpace.Width = 0.75
                let effectiveLineWidth = lineWidth.value > minLineWidth.value ? lineWidth : minLineWidth

                context.emitLine(
                    from: startPoint,
                    to: endPoint,
                    color: color,
                    width: effectiveLineWidth
                )
            }

            // Add link annotation if this segment has a URL
            if let url = currentLinkURL {
                let linkRect = PDF.UserSpace.Rectangle(
                    x: segmentStartX,
                    y: PDF.UserSpace.Y(textY.value - size.value * 0.85),
                    width: segmentWidth,
                    height: PDF.UserSpace.Height(size.value * 1.15)
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
                currentVerticalOffset = token.verticalOffset
                currentLinkURL = token.linkURL
            }

            currentX = PDF.UserSpace.X(PDF.UserSpace.Unit(currentX.value + token.width.value))
        }

        // Flush remaining segment
        flushSegment()
    }
}
