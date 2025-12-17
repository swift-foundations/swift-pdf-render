// PDF.Context.TextRun+Rendering.swift
// Optimized streaming renderer for text rendering

import INCITS_4_1986
public import PDF_Standard

// MARK: - Text Run Rendering

extension PDF.Context.TextRun {
    /// Render multiple text runs with proper line wrapping.
    ///
    /// This algorithm combines tokenization and line building in a single pass,
    /// avoiding intermediate Token and Line arrays for better performance.
    ///
    /// Features:
    /// - Line wrapping based on available width
    /// - Text alignment (leading, center, trailing)
    /// - Text decoration (underline, strikethrough, highlight)
    /// - Link annotations (external URLs and internal anchors)
    /// - Vertical offset (subscript/superscript)
    /// - Page break handling
    public static func renderRuns(
        _ runs: [PDF.Context.TextRun],
        context: inout PDF.Context
    ) {
        guard !runs.isEmpty else { return }

        let maxWidth = context.layoutBox.width
        let preserveWhitespace = context.preserveWhitespace

        // Reusable buffers for current word and line tokens
        var currentWord: [UInt8] = []
        currentWord.reserveCapacity(64)

        var lineTokens: [StreamToken] = []
        lineTokens.reserveCapacity(64)

        var currentLineWidth: PDF.UserSpace.Width = 0
        var lastWasWhitespace = !preserveWhitespace
        var isFirstLine = true

        // Cache space width per run to avoid repeated calculation
        var cachedSpaceWidth: PDF.UserSpace.Width = 0
        var cachedSpaceRun: PDF.Context.TextRun?

        // Process all runs
        for run in runs {
            // Cache space width for this run
            if cachedSpaceRun?.font != run.font || cachedSpaceRun?.fontSize != run.fontSize {
                cachedSpaceWidth = run.font.winAnsi.width(of: [.ascii.space], atSize: run.fontSize)
                cachedSpaceRun = run
            }

            for byte in run.bytes {
                switch byte {
                case .ascii.newline:
                    // Flush current word to line
                    if !currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: currentWord, atSize: run.fontSize)
                        lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                        currentWord.removeAll(keepingCapacity: true)
                    }
                    // Render current line
                    if !lineTokens.isEmpty || preserveWhitespace {
                        renderLine(lineTokens, context: &context, isFirstLine: isFirstLine)
                        isFirstLine = false
                    }
                    lineTokens.removeAll(keepingCapacity: true)
                    currentLineWidth = 0
                    lastWasWhitespace = !preserveWhitespace

                case .ascii.space:
                    // Flush current word to line
                    if !currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: currentWord, atSize: run.fontSize)
                        // Check if word fits on current line
                        if lineTokens.isEmpty {
                            lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                            currentLineWidth = width
                        } else if currentLineWidth + width <= maxWidth {
                            lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                            currentLineWidth = currentLineWidth + width
                        } else {
                            // Line full - render and start new line
                            renderLine(lineTokens, context: &context, isFirstLine: isFirstLine)
                            isFirstLine = false
                            lineTokens.removeAll(keepingCapacity: true)
                            lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                            currentLineWidth = width
                        }
                        currentWord.removeAll(keepingCapacity: true)
                        lastWasWhitespace = false
                    }
                    // Add space between words
                    if preserveWhitespace || (!lastWasWhitespace && !lineTokens.isEmpty) {
                        lineTokens.append(StreamToken(bytes: [], run: run, width: cachedSpaceWidth, kind: .space))
                        currentLineWidth = currentLineWidth + cachedSpaceWidth
                    }
                    lastWasWhitespace = true

                case .ascii.htab:
                    // Flush current word
                    if !currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: currentWord, atSize: run.fontSize)
                        if lineTokens.isEmpty || currentLineWidth + width <= maxWidth {
                            lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                            currentLineWidth = currentLineWidth + width
                        } else {
                            renderLine(lineTokens, context: &context, isFirstLine: isFirstLine)
                            isFirstLine = false
                            lineTokens.removeAll(keepingCapacity: true)
                            lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                            currentLineWidth = width
                        }
                        currentWord.removeAll(keepingCapacity: true)
                    }
                    // Add tab (4 spaces)
                    let tabWidth = cachedSpaceWidth * 4
                    if currentLineWidth + tabWidth <= maxWidth {
                        lineTokens.append(StreamToken(bytes: [], run: run, width: tabWidth, kind: .tab))
                        currentLineWidth = currentLineWidth + tabWidth
                    }
                    lastWasWhitespace = true

                default:
                    currentWord.append(byte)
                }
            }

            // Flush any remaining word from this run
            if !currentWord.isEmpty {
                let width = run.font.winAnsi.width(of: currentWord, atSize: run.fontSize)
                if lineTokens.isEmpty {
                    lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                    currentLineWidth = width
                } else if currentLineWidth + width <= maxWidth {
                    lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                    currentLineWidth = currentLineWidth + width
                } else {
                    renderLine(lineTokens, context: &context, isFirstLine: isFirstLine)
                    isFirstLine = false
                    lineTokens.removeAll(keepingCapacity: true)
                    lineTokens.append(StreamToken(bytes: currentWord, run: run, width: width, kind: .word))
                    currentLineWidth = width
                }
                currentWord.removeAll(keepingCapacity: true)
                lastWasWhitespace = false
            }
        }

        // Render final line
        if !lineTokens.isEmpty {
            renderLine(lineTokens, context: &context, isFirstLine: isFirstLine)
        }
    }

    /// Lightweight token for streaming renderer
    private struct StreamToken {
        let bytes: [UInt8]
        let run: PDF.Context.TextRun  // Reference to original run for style info
        let width: PDF.UserSpace.Width
        let kind: Kind

        enum Kind {
            case word
            case space
            case tab
        }
    }

    /// Render a line from stream tokens
    private static func renderLine(
        _ tokens: [StreamToken],
        context: inout PDF.Context,
        isFirstLine: Bool
    ) {
        // Trim trailing whitespace
        var endIndex = tokens.count
        while endIndex > 0 && tokens[endIndex - 1].kind != .word {
            endIndex -= 1
        }
        guard endIndex > 0 else { return }

        let lineHeight = context.style.line.height
        context.checkPageBreak(needing: lineHeight)

        // Handle list marker on first line
        if isFirstLine, let pending = context.pendingListMarker {
            let markerBaselineY = context.layoutBox.lly + context.style.line.baselineOffset
            let baseFont = context.style.font
            let baseFontSize = context.style.fontSize

            switch pending.marker {
            case .text(let bytes, let font):
                context.emitText(
                    bytes,
                    at: PDF.UserSpace.Coordinate(x: pending.x, y: markerBaselineY),
                    font: font,
                    size: context.style.fontSize,
                    color: context.style.color
                )

            case .strokedCircle(let circle, let strokeWidth):
                let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                let centerY = markerBaselineY - xHeight * 0.6
                let centerX = pending.x + circle.radius
                context.emitCircle(
                    center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                    radius: circle.radius,
                    fill: nil,
                    stroke: context.style.color,
                    strokeWidth: strokeWidth
                )

            case .filledCircle(let circle):
                let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                let centerY = markerBaselineY - xHeight / 2
                let centerX = pending.x + circle.radius
                context.emitCircle(
                    center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                    radius: circle.radius,
                    fill: context.style.color,
                    stroke: nil
                )

            case .filledSquare(let square):
                let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
                let squareY = markerBaselineY - xHeight / 2 - square.height / 2
                let rect = PDF.UserSpace.Rectangle(
                    x: pending.x,
                    y: squareY,
                    width: square.width,
                    height: square.height
                )
                context.emitRectangle(rect, fill: context.style.color, stroke: nil)
            }
            context.pendingListMarker = nil
        }

        // Calculate baseline Y
        let baselineY = context.layoutBox.lly + context.style.line.baselineOffset

        // Calculate line width for alignment
        var totalWidth: PDF.UserSpace.Width = 0
        for i in 0..<endIndex {
            totalWidth = totalWidth + tokens[i].width
        }

        // Calculate alignment offset
        let availableWidth = context.layoutBox.width
        let alignmentOffset: PDF.UserSpace.Width
        switch context.style.textAlign {
        case .leading:
            alignmentOffset = 0
        case .center:
            alignmentOffset = .max(.zero, (availableWidth - totalWidth) / 2)
        case .trailing:
            alignmentOffset = .max(.zero, availableWidth - totalWidth)
        }
        let startX = context.layoutBox.llx + alignmentOffset

        // Emit text in batched segments (minimize style switches)
        var currentX = startX
        var segmentBytes: [UInt8] = []
        segmentBytes.reserveCapacity(256)
        var segmentStartX = startX
        var currentFont: PDF.Font?
        var currentSize: PDF.UserSpace.Size<1>?
        var currentColor: PDF.Color?
        var currentDecoration: PDF.Annotation.TextMarkup.Kind?
        var currentVerticalOffset: PDF.UserSpace.Height = 0
        var currentLinkURL: String?
        var currentInternalLinkId: String?

        func flushSegment() {
            guard !segmentBytes.isEmpty,
                  let font = currentFont,
                  let size = currentSize,
                  let color = currentColor
            else { return }

            let segmentWidth = font.winAnsi.width(of: segmentBytes, atSize: size)
            let textY = baselineY - currentVerticalOffset

            // Draw highlight background BEFORE text
            if case .highlight(let annotationColor) = currentDecoration {
                let fillColor: PDF.Color =
                    switch annotationColor {
                    case .transparent: .gray(1)
                    case .gray(let g): .gray(g)
                    case .rgb(let r, let g, let b): .rgb(r: r, g: g, b: b)
                    case .cmyk(let c, let m, let y, let k): .cmyk(c: c, m: m, y: y, k: k)
                    }
                let bgRect = PDF.UserSpace.Rectangle(
                    x: segmentStartX,
                    y: textY - (size * 0.85).height,
                    width: segmentWidth,
                    height: (size * 1.15).height
                )
                context.emitRectangle(bgRect, fill: fillColor, stroke: nil)
            }

            // Emit text
            context.emitText(
                segmentBytes,
                at: PDF.UserSpace.Coordinate(x: segmentStartX, y: textY),
                font: font,
                size: size,
                color: color
            )

            // Draw text decoration
            if let decoration = currentDecoration {
                switch decoration {
                case .underline:
                    let underlineY = textY + (size * 0.15).height
                    let lineWidth = max((size * 0.05).width, PDF.UserSpace.Width(0.5))
                    context.emitLine(
                        from: PDF.UserSpace.Coordinate(x: segmentStartX, y: underlineY),
                        to: PDF.UserSpace.Coordinate(x: segmentStartX + segmentWidth, y: underlineY),
                        color: color,
                        width: lineWidth
                    )

                case .strikeOut:
                    let xHeight = font.metrics.xHeight(atSize: size)
                    let strikeY = textY - xHeight / 2
                    let lineWidth = max((size * 0.05).width, PDF.UserSpace.Width(0.5))
                    context.emitLine(
                        from: PDF.UserSpace.Coordinate(x: segmentStartX, y: strikeY),
                        to: PDF.UserSpace.Coordinate(x: segmentStartX + segmentWidth, y: strikeY),
                        color: color,
                        width: lineWidth
                    )

                case .highlight:
                    break  // Already handled above

                case .squiggly:
                    break
                }
            }

            // Add link annotation if present
            let linkRect = PDF.UserSpace.Rectangle(
                x: segmentStartX,
                y: textY - size.height * 0.85,
                width: segmentWidth,
                height: size.height * 1.15
            )
            if let internalId = currentInternalLinkId {
                context.addPendingInternalLink(rect: linkRect, targetId: internalId)
            } else if let url = currentLinkURL {
                context.addLinkAnnotation(rect: linkRect, uri: url)
            }

            segmentBytes.removeAll(keepingCapacity: true)
        }

        for i in 0..<endIndex {
            let token = tokens[i]

            if token.kind == .space || token.kind == .tab {
                // Flush segment before space
                flushSegment()
                currentX = currentX + token.width
                segmentStartX = currentX
                continue
            }

            // Check if style changed
            let styleChanged = currentFont != token.run.font ||
                              currentSize != token.run.fontSize ||
                              currentColor != token.run.color ||
                              currentDecoration != token.run.textDecoration ||
                              currentVerticalOffset != token.run.verticalOffset ||
                              currentLinkURL != token.run.linkURL ||
                              currentInternalLinkId != token.run.internalLinkId

            if styleChanged && !segmentBytes.isEmpty {
                // Flush previous segment
                flushSegment()
                segmentStartX = currentX
            }

            currentFont = token.run.font
            currentSize = token.run.fontSize
            currentColor = token.run.color
            currentDecoration = token.run.textDecoration
            currentVerticalOffset = token.run.verticalOffset
            currentLinkURL = token.run.linkURL
            currentInternalLinkId = token.run.internalLinkId
            segmentBytes.append(contentsOf: token.bytes)
            currentX = currentX + token.width
        }

        // Flush final segment
        flushSegment()

        // Advance Y position
        context.layoutBox.lly = context.layoutBox.lly - lineHeight
    }
}
