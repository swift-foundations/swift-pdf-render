// PDF.Context.TextRun.swift

public import PDF_Standard
import INCITS_4_1986

extension PDF.Context {
    /// A styled text segment for inline text flow.
    ///
    /// TextRuns accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct TextRun: Sendable {
        /// The text content as WinAnsi-encoded bytes
        public let bytes: [UInt8]

        /// Font for this text segment
        public let font: PDF.Font

        /// Font size in points
        public let fontSize: PDF.UserSpace.Unit

        /// Text color
        public let color: PDF.Color

        /// Text decoration (underline, strikethrough, etc.)
        public let textDecoration: PDF.Annotation.TextMarkup.Kind?

        /// Vertical offset for subscript/superscript (positive = up, negative = down)
        public let verticalOffset: PDF.UserSpace.Unit

        /// Optional link URL (makes this text a clickable external link)
        public let linkURL: String?

        /// Optional internal link target ID (for #anchor links)
        /// Used to create pending internal links that are resolved after rendering completes.
        public let internalLinkId: String?

        /// Create a text run from a String (encodes to WinAnsi)
        public init(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Unit,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            backgroundColor: PDF.Color? = nil,
            verticalOffset: PDF.UserSpace.Unit = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            // Encode to WinAnsi, preserving control characters for tokenizer.
            // Control chars (newline, tab, etc.) are handled specially by the tokenizer
            // and must remain as their raw byte values, not be converted to '?'.
            self.bytes = [UInt8](winAnsi: text, withFallback: true, preservingControlChars: true)
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create a text run from pre-encoded bytes
        public init(
            bytes: [UInt8],
            font: PDF.Font,
            fontSize: PDF.UserSpace.Unit,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Unit = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            self.bytes = bytes
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create text runs from a String, automatically switching to ZapfDingbats for symbols.
        ///
        /// This method scans the text for characters that:
        /// - Can be encoded in WinAnsi → uses the provided font
        /// - Can be encoded in ZapfDingbats but not WinAnsi → switches to ZapfDingbats font
        /// - Cannot be encoded in either → uses the fallback character
        ///
        /// - Parameters:
        ///   - text: The text to convert
        ///   - font: The primary font to use for regular text
        ///   - fontSize: Font size
        ///   - color: Text color
        ///   - textDecoration: Optional text decoration
        ///   - verticalOffset: Vertical offset for sub/superscript
        ///   - linkURL: Optional external link URL
        ///   - internalLinkId: Optional internal link target ID (for #anchor links)
        /// - Returns: Array of TextRuns, possibly with different fonts
        public static func runsWithSymbolSupport(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Unit,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Unit = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) -> [TextRun] {
            var runs: [TextRun] = []
            var currentWinAnsiBytes: [UInt8] = []
            var currentDingbatsBytes: [UInt8] = []

            func flushWinAnsi() {
                guard !currentWinAnsiBytes.isEmpty else { return }
                runs.append(TextRun(
                    bytes: currentWinAnsiBytes,
                    font: font,
                    fontSize: fontSize,
                    color: color,
                    textDecoration: textDecoration,
                    verticalOffset: verticalOffset,
                    linkURL: linkURL,
                    internalLinkId: internalLinkId
                ))
                currentWinAnsiBytes = []
            }

            func flushDingbats() {
                guard !currentDingbatsBytes.isEmpty else { return }
                runs.append(TextRun(
                    bytes: currentDingbatsBytes,
                    font: .zapfDingbats,
                    fontSize: fontSize,
                    color: color,
                    textDecoration: textDecoration,
                    verticalOffset: verticalOffset,
                    linkURL: linkURL,
                    internalLinkId: internalLinkId
                ))
                currentDingbatsBytes = []
            }

            for scalar in text.unicodeScalars {
                let value = scalar.value

                // Preserve control characters (0x00-0x1F) as-is for tokenizer
                // This includes newlines (0x0A), tabs (0x09), etc.
                if value < 0x20 {
                    flushDingbats()
                    currentWinAnsiBytes.append(UInt8(value))
                }
                // Try WinAnsi first (primary encoding)
                else if let byte = ISO_32000.WinAnsiEncoding.encode(scalar) {
                    flushDingbats()
                    currentWinAnsiBytes.append(byte)
                }
                // Try ZapfDingbats for symbols
                else if let byte = ISO_32000.ZapfDingbatsEncoding.encode(scalar) {
                    flushWinAnsi()
                    currentDingbatsBytes.append(byte)
                }
                // Use fallback from the map, or '?' as last resort
                else if let fallback = ISO_32000.unicodeFallbackMap[value] {
                    flushDingbats()
                    currentWinAnsiBytes.append(contentsOf: fallback)
                }
                else {
                    flushDingbats()
                    currentWinAnsiBytes.append(0x3F) // '?'
                }
            }

            // Flush remaining bytes
            flushWinAnsi()
            flushDingbats()

            return runs
        }

        /// Render multiple text runs with proper line wrapping.
        ///
        /// This algorithm:
        /// 1. Tokenizes all runs into words with their styling
        /// 2. Builds lines by accumulating words until width exceeds available
        /// 3. Emits content directly to context's content stream
        /// 4. Handles page breaks automatically when lines exceed page boundary
        public static func renderRuns(
            _ runs: [PDF.Context.TextRun],
            context: inout PDF.Context
        ) {
            guard !runs.isEmpty else { return }

            // Tokenize runs into styled words (preserve whitespace for preformatted text)
            let tokens = tokenize(runs, preserveWhitespace: context.preserveWhitespace)
            guard !tokens.isEmpty else { return }

            // Build lines from tokens
            let lines = buildLines(tokens, maxWidth: context.layoutBox.width, preserveWhitespace: context.preserveWhitespace)

            // Render lines with pagination support
            var isFirstLine = true
            for line in lines {
                // Check if this line would exceed the page
                let lineHeight = context.style.lineHeightPoints
                context.checkPageBreak(needing: lineHeight)

                // Emit pending list marker on the first line
                if isFirstLine, let pending = context.pendingListMarker {
                    // Calculate baseline Y for the marker using half-leading model
                    // This ensures the marker aligns with text that is centered within its line box.
                    let baselineY = PDF.UserSpace.Y(context.layoutBox.lly.value + context.style.baselineOffset)

                    // For circle/square markers, we need font metrics for x-height positioning
                    let baseFont = context.style.font
                    let baseFontSize = context.style.fontSize

                    // Emit marker based on its type
                    switch pending.marker {
                    case .text(let bytes, let font):
                        context.emitText(
                            bytes,
                            at: PDF.UserSpace.Coordinate(x: pending.x, y: baselineY),
                            font: font,
                            size: context.style.fontSize,
                            color: context.style.color
                        )

                    case .strokedCircle(let circle, let strokeWidth):
                        // Position circle vertically centered at middle of x-height
                        // In top-left coordinates (Y increases downward), subtracting moves up
                        let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                        // Center at 60% of x-height above baseline for better optical alignment
                        // (slightly higher than mathematical center looks better with hollow circles)
                        let centerYValue = baselineY.value - xHeight * 0.6
                        let centerY = PDF.UserSpace.Y(centerYValue)
                        // Center circle horizontally at marker position
                        let centerXValue = pending.x.value + circle.radius.value
                        let centerX = PDF.UserSpace.X(centerXValue)
                        context.emitCircle(
                            center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                            radius: circle.radius,
                            fill: nil,
                            stroke: context.style.color,
                            strokeWidth: .init(strokeWidth)
                        )

                    case .filledCircle(let circle):
                        // Position circle vertically centered on x-height
                        let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                        let centerYValue = baselineY.value.value - xHeight.value / 2.0
                        let centerY = PDF.UserSpace.Y(PDF.UserSpace.Unit(centerYValue))
                        let centerXValue = pending.x.value.value + circle.radius.value.value
                        let centerX = PDF.UserSpace.X(PDF.UserSpace.Unit(centerXValue))
                        context.emitCircle(
                            center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                            radius: circle.radius,
                            fill: context.style.color,
                            stroke: nil
                        )

                    case .filledSquare(let square):
                        // Position square vertically centered on x-height
                        let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                        let squareYValue = baselineY.value.value - xHeight.value / 2.0 - square.size.height.value.value / 2.0
                        let squareY = PDF.UserSpace.Y(PDF.UserSpace.Unit(squareYValue))
                        let rect = PDF.UserSpace.Rectangle(
                            x: pending.x,
                            y: squareY,
                            width: square.width,
                            height: square.height
                        )
                        context.emitRectangle(rect, fill: context.style.color, stroke: nil)
                    }

                    context.pendingListMarker = nil
                    isFirstLine = false
                }

                // Render line content
                renderLine(line, context: &context)

                // Advance to next line
                context.advanceLine()
            }
        }
    }
}

// MARK: - Tokenization

extension PDF.Context.TextRun {
    /// Token representing a word or space with its styling
    struct Token: Sendable {
        let bytes: [UInt8]
        let font: PDF.Font
        let fontSize: PDF.UserSpace.Unit
        let color: PDF.Color
        let textDecoration: PDF.Annotation.TextMarkup.Kind?
        let verticalOffset: PDF.UserSpace.Unit
        let linkURL: String?
        let internalLinkId: String?
        let isWhitespace: Bool
        let isNewline: Bool
        let isTab: Bool

        var width: PDF.UserSpace.Unit {
            font.winAnsi.width(of: bytes, atSize: fontSize)
        }
    }

    /// Tokenize runs into words with styling
    static func tokenize(_ runs: [PDF.Context.TextRun], preserveWhitespace: Bool = false) -> [Token] {
        var tokens: [Token] = []

        for run in runs {
            var currentWord: [UInt8] = []

            for byte in run.bytes {
                if byte == .ascii.newline {
                    // Flush current word
                    if !currentWord.isEmpty {
                        tokens.append(Token(
                            bytes: currentWord,
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL,
                            internalLinkId: run.internalLinkId,
                            isWhitespace: false,
                            isNewline: false,
                            isTab: false
                        ))
                        currentWord = []
                    }
                    // Add newline token
                    tokens.append(Token(
                        bytes: [],
                        font: run.font,
                        fontSize: run.fontSize,
                        color: run.color,
                        textDecoration: run.textDecoration,
                        verticalOffset: run.verticalOffset,
                        linkURL: run.linkURL,
                        internalLinkId: run.internalLinkId,
                        isWhitespace: true,
                        isNewline: true,
                        isTab: false
                    ))
                } else if byte == .ascii.htab {
                    // Flush current word
                    if !currentWord.isEmpty {
                        tokens.append(Token(
                            bytes: currentWord,
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL,
                            internalLinkId: run.internalLinkId,
                            isWhitespace: false,
                            isNewline: false,
                            isTab: false
                        ))
                        currentWord = []
                    }
                    // Add tab token
                    tokens.append(Token(
                        bytes: [],
                        font: run.font,
                        fontSize: run.fontSize,
                        color: run.color,
                        textDecoration: run.textDecoration,
                        verticalOffset: run.verticalOffset,
                        linkURL: run.linkURL,
                        internalLinkId: run.internalLinkId,
                        isWhitespace: true,
                        isNewline: false,
                        isTab: true
                    ))
                } else if byte == .ascii.space {
                    // Flush current word
                    if !currentWord.isEmpty {
                        tokens.append(Token(
                            bytes: currentWord,
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL,
                            internalLinkId: run.internalLinkId,
                            isWhitespace: false,
                            isNewline: false,
                            isTab: false
                        ))
                        currentWord = []
                    }
                    // Add space token (preserve for inline flow)
                    if preserveWhitespace {
                        tokens.append(Token(
                            bytes: [.ascii.space],
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL,
                            internalLinkId: run.internalLinkId,
                            isWhitespace: true,
                            isNewline: false,
                            isTab: false
                        ))
                    } else {
                        // Mark space but don't include bytes (will be added during line building)
                        tokens.append(Token(
                            bytes: [],
                            font: run.font,
                            fontSize: run.fontSize,
                            color: run.color,
                            textDecoration: run.textDecoration,
                            verticalOffset: run.verticalOffset,
                            linkURL: run.linkURL,
                            internalLinkId: run.internalLinkId,
                            isWhitespace: true,
                            isNewline: false,
                            isTab: false
                        ))
                    }
                } else {
                    currentWord.append(byte)
                }
            }

            // Flush remaining word
            if !currentWord.isEmpty {
                tokens.append(Token(
                    bytes: currentWord,
                    font: run.font,
                    fontSize: run.fontSize,
                    color: run.color,
                    textDecoration: run.textDecoration,
                    verticalOffset: run.verticalOffset,
                    linkURL: run.linkURL,
                    internalLinkId: run.internalLinkId,
                    isWhitespace: false,
                    isNewline: false,
                    isTab: false
                ))
            }
        }

        return tokens
    }
}

// MARK: - Line Building

extension PDF.Context.TextRun {
    /// A line of tokens ready for rendering
    struct Line: Sendable {
        var tokens: [Token]

        /// Get tokens without trailing whitespace
        var trimmedTokens: [Token] {
            var result = tokens
            while let last = result.last, last.isWhitespace {
                result.removeLast()
            }
            return result
        }
    }

    /// Build lines from tokens
    static func buildLines(_ tokens: [Token], maxWidth: PDF.UserSpace.Width, preserveWhitespace: Bool = false) -> [Line] {
        var lines: [Line] = []
        var currentLine = Line(tokens: [])
        var currentWidth: PDF.UserSpace.Unit = 0
        // When preserving whitespace (preformatted text), don't skip leading whitespace
        var lastWasWhitespace = !preserveWhitespace

        for token in tokens {
            // Handle newlines
            if token.isNewline {
                lines.append(currentLine)
                currentLine = Line(tokens: [])
                currentWidth = 0
                // After newline, preserve leading whitespace if in preformatted mode
                lastWasWhitespace = !preserveWhitespace
                continue
            }

            // Handle tabs (convert to spaces for now)
            if token.isTab {
                let tabWidth = token.font.winAnsi.width(of: [.ascii.space, .ascii.space, .ascii.space, .ascii.space], atSize: token.fontSize)
                if currentWidth + tabWidth <= maxWidth.value {
                    currentLine.tokens.append(token)
                    currentWidth = currentWidth + tabWidth
                }
                lastWasWhitespace = true
                continue
            }

            // Handle regular whitespace
            if token.isWhitespace {
                if preserveWhitespace || (!lastWasWhitespace && !currentLine.tokens.isEmpty) {
                    // In preformatted mode, always add whitespace
                    // Otherwise, add space only between words
                    currentLine.tokens.append(token)
                    currentWidth = currentWidth + token.font.winAnsi.width(of: [.ascii.space], atSize: token.fontSize)
                }
                lastWasWhitespace = true
                continue
            }

            // Handle words
            let wordWidth = token.width

            // Check if word fits on current line
            if currentLine.tokens.isEmpty {
                // First word on line - always add it even if it exceeds width
                currentLine.tokens.append(token)
                currentWidth = wordWidth
            } else if currentWidth + wordWidth <= maxWidth.value {
                // Word fits
                currentLine.tokens.append(token)
                currentWidth = currentWidth + wordWidth
            } else {
                // Word doesn't fit - start new line
                lines.append(currentLine)
                currentLine = Line(tokens: [token])
                currentWidth = wordWidth
            }

            lastWasWhitespace = false
        }

        // Add final line if non-empty
        if !currentLine.tokens.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }
}

// MARK: - Line Rendering

extension PDF.Context.TextRun {
    /// Render a single line of tokens directly to context.
    static func renderLine(_ line: Line, context: inout PDF.Context) {
        // Use trimmed tokens to avoid trailing spaces
        let tokens = line.trimmedTokens

        // Calculate total line width for alignment
        var totalLineWidth: PDF.UserSpace.Unit = 0
        for (index, token) in tokens.enumerated() {
            totalLineWidth += token.width
            // Add space width between words (same logic as rendering below)
            if token.isWhitespace && index < tokens.count - 1 {
                totalLineWidth += token.font.winAnsi.width(of: [.ascii.space], atSize: token.fontSize)
            }
        }

        // Calculate alignment offset
        let availableWidth = context.layoutBox.width.value
        let alignmentOffset: PDF.UserSpace.Unit
        switch context.style.textAlign {
        case .leading:
            alignmentOffset = 0
        case .center:
            alignmentOffset = PDF.UserSpace.Unit(Swift.max(0, (availableWidth.value - totalLineWidth.value) / 2.0))
        case .trailing:
            alignmentOffset = PDF.UserSpace.Unit(Swift.max(0, availableWidth.value - totalLineWidth.value))
        }

        var currentX = PDF.UserSpace.X(context.layoutBox.llx.value + alignmentOffset)

        // Calculate line baseline using half-leading model
        // This ensures symmetric spacing above and below text within the line box.
        // The baselineOffset includes halfLeading + ascender, positioning text
        // centered within the line height rather than anchored at the top.
        let lineBaselineY = PDF.UserSpace.Y(context.layoutBox.lly.value + context.style.baselineOffset)

        // Group consecutive tokens with same styling
        var currentSegment: [UInt8] = []
        var currentFont: PDF.Font?
        var currentSize: PDF.UserSpace.Unit?
        var currentColor: PDF.Color?
        var currentDecoration: PDF.Annotation.TextMarkup.Kind?
        var currentVerticalOffset: PDF.UserSpace.Unit = 0
        var currentLinkURL: String? = nil
        var currentInternalLinkId: String? = nil
        var segmentStartX = currentX

        func flushSegment() {
            guard !currentSegment.isEmpty,
                  let font = currentFont,
                  let size = currentSize,
                  let color = currentColor else { return }

            let segmentWidth = PDF.UserSpace.Width(font.winAnsi.width(of: currentSegment, atSize: size))
            // Use the line's consistent baseline, adjusted for vertical offset (sub/superscript)
            let textY = PDF.UserSpace.Y(lineBaselineY.value - currentVerticalOffset)

            // Draw highlight background BEFORE text (so text appears on top)
            if case .highlight(let annotationColor) = currentDecoration {
                // Convert annotation color to graphics color
                let fillColor: PDF.Color = switch annotationColor {
                case .transparent: .gray(1) // fallback to white
                case .gray(let g): .gray(g)
                case .rgb(let r, let g, let b): .rgb(r: r, g: g, b: b)
                case .cmyk(let c, let m, let y, let k): .cmyk(c: c, m: m, y: y, k: k)
                }
                let bgRect = PDF.UserSpace.Rectangle(
                    x: segmentStartX,
                    y: PDF.UserSpace.Y(textY.value - size.value * 0.85),
                    width: segmentWidth,
                    height: PDF.UserSpace.Height(size.value * 1.15)
                )
                context.emitRectangle(bgRect, fill: fillColor, stroke: nil)
            }

            // Emit bytes directly to context
            context.emitText(
                currentSegment,
                at: PDF.UserSpace.Coordinate(x: segmentStartX, y: textY),
                font: font,
                size: size,
                color: color
            )

            // Draw text decoration if present (underline, strikethrough)
            if let decoration = currentDecoration {
                switch decoration {
                case .underline:
                    // Position underline slightly below baseline
                    let underlineY = PDF.UserSpace.Y(textY.value + size * 0.15)
                    context.emitLine(
                        from: PDF.UserSpace.Coordinate(x: segmentStartX, y: underlineY),
                        to: PDF.UserSpace.Coordinate(x: PDF.UserSpace.X(segmentStartX.value + segmentWidth.value), y: underlineY),
                        color: color,
                        width: .init(max(0.5, size.value * 0.05))
                    )

                case .strikeOut:
                    // Position strikethrough at middle of x-height
                    let strikeY = PDF.UserSpace.Y(PDF.UserSpace.Unit(textY.value.value - font.metrics.xHeight(atSize: size).value / 2.0))
                    context.emitLine(
                        from: PDF.UserSpace.Coordinate(x: segmentStartX, y: strikeY),
                        to: PDF.UserSpace.Coordinate(x: PDF.UserSpace.X(segmentStartX.value + segmentWidth.value), y: strikeY),
                        color: color,
                        width: .init(max(0.5, size.value * 0.05))
                    )

                case .highlight:
                    // Already handled above
                    break
                case .squiggly:
                    break
                }
            }

            // Add link annotation if present
            let linkRect = PDF.UserSpace.Rectangle(
                x: segmentStartX,
                y: PDF.UserSpace.Y(textY.value - size * 0.85),
                width: segmentWidth,
                height: PDF.UserSpace.Height(size * 1.15)
            )
            if let internalId = currentInternalLinkId {
                // Internal link - add to pending for later resolution
                context.addPendingInternalLink(rect: linkRect, targetId: internalId)
            } else if let url = currentLinkURL {
                // External link - add URI annotation directly
                context.addLinkAnnotation(rect: linkRect, uri: url)
            }

            // Advance X position
            currentX = PDF.UserSpace.X(segmentStartX.value + segmentWidth.value)
            currentSegment = []
        }

        for token in tokens {
            // Handle whitespace
            if token.isWhitespace {
                flushSegment()
                let spaceWidth = token.font.winAnsi.width(of: [.ascii.space], atSize: token.fontSize)
                currentX = PDF.UserSpace.X(currentX.value + spaceWidth)
                segmentStartX = currentX
                continue
            }

            // Check if styling changed
            let stylingChanged = (
                currentFont != token.font ||
                currentSize != token.fontSize ||
                currentColor != token.color ||
                currentDecoration != token.textDecoration ||
                currentVerticalOffset != token.verticalOffset ||
                currentLinkURL != token.linkURL ||
                currentInternalLinkId != token.internalLinkId
            )

            if stylingChanged {
                flushSegment()
                currentFont = token.font
                currentSize = token.fontSize
                currentColor = token.color
                currentDecoration = token.textDecoration
                currentVerticalOffset = token.verticalOffset
                currentLinkURL = token.linkURL
                currentInternalLinkId = token.internalLinkId
                segmentStartX = currentX
            }

            // Add token bytes to current segment
            currentSegment.append(contentsOf: token.bytes)
        }

        // Flush final segment
        flushSegment()
    }
}
