// PDF.Context.Text.Run+Render.swift
// Optimized text renderer with minimal allocations

import ASCII
import Layout_Primitives
public import PDF_Standard

// MARK: - Text Run Rendering

extension PDF.Context.Text.Run {
    /// Render multiple text runs with proper line wrapping.
    ///
    /// This implementation minimizes allocations by:
    /// - Using a shared byte buffer for all words on a line
    /// - Storing compact word descriptors instead of copying bytes
    /// - Reusing buffers across lines
    public static func renderRuns(
        _ runs: [PDF.Context.Text.Run],
        context: inout PDF.Context
    ) {
        guard !runs.isEmpty else { return }

        // Build ActualText for proper copy-paste behavior
        // This provides the semantic text for extraction, separate from visual line wrapping
        let actualText = buildActualText(from: runs)
        if !actualText.isEmpty {
            context.currentPageBuilder.beginActualTextSpan(actualText)
        }
        defer {
            if !actualText.isEmpty {
                context.currentPageBuilder.endActualTextSpan()
            }
        }

        let maxWidth = context.layout.box.width
        let preserveWhitespace = context.mode.preserveWhitespace
        // CSS `white-space: nowrap` / `pre`: suppress line-wrap on overflow.
        // Content extends past `maxWidth`; lines emit only on explicit `\n`
        // or end-of-input. Equivalent to treating `maxWidth` as infinite for
        // the wrap-on-overflow decision while keeping the rest of the layout
        // logic intact (gaps, words, alignment).
        let wrapAllowed = !context.mode.noWrap

        // Shared state - reused across lines
        var state = RenderState()
        state.lineBytes.reserveCapacity(512)
        state.words.reserveCapacity(32)
        state.currentWord.reserveCapacity(64)

        var currentLineWidth: PDF.UserSpace.Width = .init(0)
        var lastWasWhitespace = !preserveWhitespace
        var isFirstLine = true
        var currentRunIndex = 0

        // Cache space width
        var cachedSpaceWidth: PDF.UserSpace.Width = .init(0)
        var cachedSpaceFont: PDF.Font?
        var cachedSpaceFontSize: PDF.UserSpace.Size<1>?

        // Process all runs
        for run in runs {
            // Cache space width for this run
            if cachedSpaceFont != run.font || cachedSpaceFontSize != run.fontSize {
                cachedSpaceWidth = run.font.winAnsi.width(of: [.ascii.space], atSize: run.fontSize)
                cachedSpaceFont = run.font
                cachedSpaceFontSize = run.fontSize
            }

            for byte in run.bytes {
                switch byte {
                case .ascii.newline:
                    // Flush current word
                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)
                        state.appendWord(width: width, runIndex: currentRunIndex)
                        currentLineWidth = currentLineWidth + width
                    }
                    // Render line
                    if !state.words.isEmpty || preserveWhitespace {
                        emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
                        isFirstLine = false
                    }
                    state.clearLine()
                    currentLineWidth = .init(0)
                    lastWasWhitespace = !preserveWhitespace

                case .ascii.space:
                    // Flush current word
                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)

                        if state.words.isEmpty {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        } else if !wrapAllowed || currentLineWidth + width <= maxWidth {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = currentLineWidth + width
                        } else {
                            // Line full
                            emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
                            isFirstLine = false
                            state.clearLine()
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        }
                        lastWasWhitespace = false
                    }
                    // Add space
                    if preserveWhitespace || (!lastWasWhitespace && !state.words.isEmpty) {
                        state.addGap(cachedSpaceWidth)
                        currentLineWidth = currentLineWidth + cachedSpaceWidth
                    }
                    lastWasWhitespace = true

                case .ascii.htab:
                    // Flush current word
                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)
                        if state.words.isEmpty || !wrapAllowed || currentLineWidth + width <= maxWidth {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = currentLineWidth + width
                        } else {
                            emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
                            isFirstLine = false
                            state.clearLine()
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        }
                    }
                    // Add tab
                    let tabWidth = cachedSpaceWidth * 4
                    if !wrapAllowed || currentLineWidth + tabWidth <= maxWidth {
                        state.addGap(tabWidth)
                        currentLineWidth = currentLineWidth + tabWidth
                    }
                    lastWasWhitespace = true

                default:
                    state.currentWord.append(byte)
                }
            }

            // Flush remaining word from this run
            if !state.currentWord.isEmpty {
                let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)
                if state.words.isEmpty {
                    state.appendWord(width: width, runIndex: currentRunIndex)
                    currentLineWidth = width
                } else if !wrapAllowed || currentLineWidth + width <= maxWidth {
                    state.appendWord(width: width, runIndex: currentRunIndex)
                    currentLineWidth = currentLineWidth + width
                } else {
                    emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
                    isFirstLine = false
                    state.clearLine()
                    state.appendWord(width: width, runIndex: currentRunIndex)
                    currentLineWidth = width
                }
                lastWasWhitespace = false
            }

            currentRunIndex += 1
        }

        // Render final line
        if !state.words.isEmpty {
            emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
        }
    }

    // MARK: - Render State

    /// Compact state for rendering - avoids per-word allocations
    private struct RenderState {
        /// Shared buffer for all word bytes on current line
        var lineBytes: [UInt8] = []

        /// Word descriptors (indices into lineBytes, no byte copies)
        var words: [WordDescriptor] = []

        /// Current word being accumulated
        var currentWord: [UInt8] = []

        /// Append current word to line
        mutating func appendWord(width: PDF.UserSpace.Width, runIndex: Int) {
            let start = lineBytes.count
            lineBytes.append(contentsOf: currentWord)
            words.append(WordDescriptor(
                byteStart: start,
                byteLength: currentWord.count,
                width: width,
                gapAfter: .init(0),
                runIndex: runIndex
            ))
            currentWord.removeAll(keepingCapacity: true)
        }

        /// Add gap (space/tab) after last word
        mutating func addGap(_ width: PDF.UserSpace.Width) {
            if !words.isEmpty {
                words[words.count - 1].gapAfter = words[words.count - 1].gapAfter + width
            }
        }

        /// Clear line state (reuse buffers)
        mutating func clearLine() {
            lineBytes.removeAll(keepingCapacity: true)
            words.removeAll(keepingCapacity: true)
        }
    }

    /// Compact word descriptor - no byte allocation
    private struct WordDescriptor {
        let byteStart: Int
        let byteLength: Int
        let width: PDF.UserSpace.Width
        var gapAfter: PDF.UserSpace.Width
        let runIndex: Int
    }

    // MARK: - Line Emission

    private static func emitLine(
        _ state: inout RenderState,
        runs: [PDF.Context.Text.Run],
        context: inout PDF.Context,
        isFirstLine: Bool
    ) {
        guard !state.words.isEmpty else { return }

        let lineHeight = context.style.line.height
        context.page.ensure(height: lineHeight)

        // Handle list marker
        if isFirstLine, let pending = context.list.marker {
            emitListMarker(pending.marker, at: pending.x, context: &context)
            context.list.marker = nil
        }

        let baselineY = context.layout.box.lly + context.style.line.ascent

        // Calculate total width (words + gaps, excluding trailing gap)
        var totalWidth: PDF.UserSpace.Width = .init(0)
        for i in 0..<state.words.count {
            totalWidth = totalWidth + state.words[i].width
            if i < state.words.count - 1 {
                totalWidth = totalWidth + state.words[i].gapAfter
            }
        }

        // Calculate alignment
        let availableWidth = context.layout.box.width
        let alignmentOffset: PDF.UserSpace.Width
        switch context.style.textAlign {
        case .leading:
            alignmentOffset = .init(0)
        case .center:
            alignmentOffset = .max(.zero, (availableWidth - totalWidth) / 2)
        case .trailing:
            alignmentOffset = .max(.zero, availableWidth - totalWidth)
        }

        var currentX = context.layout.box.llx + alignmentOffset

        // Emit words with batching for same-style segments
        var segmentBytes: [UInt8] = []
        segmentBytes.reserveCapacity(256)
        var segmentStartX = currentX
        var segmentWidth: PDF.UserSpace.Width = .init(0)
        var currentStyle: StyleKey?

        for word in state.words {
            let run = runs[word.runIndex]
            // IMPORTANT: Must pass word.runIndex here, not rely on default (0).
            // StyleKey.runIndex is used later in runs[style.runIndex] to fetch the
            // correct run when emitting segments (lines ~278, ~304, ~322).
            // If runIndex defaults to 0, ALL segments emit with runs[0]'s font/style,
            // causing: (1) bold/italic leaking into normal text, (2) wrong spacing
            // due to incorrect font metrics. This was a critical bug fixed in v0.4.2.
            let wordStyle = StyleKey(run: run, index: word.runIndex)

            // Check if style changed
            if let current = currentStyle, current != wordStyle {
                // Flush segment
                if !segmentBytes.isEmpty {
                    emitSegment(
                        bytes: segmentBytes,
                        at: segmentStartX,
                        width: segmentWidth,
                        baselineY: baselineY,
                        run: runs[current.runIndex],
                        context: &context
                    )
                    segmentBytes.removeAll(keepingCapacity: true)
                }
                segmentStartX = currentX
                segmentWidth = .init(0)
            }

            // Add word bytes to segment
            let wordBytes = state.lineBytes[word.byteStart..<(word.byteStart + word.byteLength)]
            segmentBytes.append(contentsOf: wordBytes)
            segmentWidth = segmentWidth + word.width
            currentStyle = wordStyle

            currentX = currentX + word.width

            // Handle gap after word
            if word.gapAfter > .init(0) {
                // Flush segment before gap
                if !segmentBytes.isEmpty, let style = currentStyle {
                    emitSegment(
                        bytes: segmentBytes,
                        at: segmentStartX,
                        width: segmentWidth,
                        baselineY: baselineY,
                        run: runs[style.runIndex],
                        context: &context
                    )
                    segmentBytes.removeAll(keepingCapacity: true)
                }
                currentX = currentX + word.gapAfter
                segmentStartX = currentX
                segmentWidth = .init(0)
            }
        }

        // Flush final segment
        if !segmentBytes.isEmpty, let style = currentStyle {
            emitSegment(
                bytes: segmentBytes,
                at: segmentStartX,
                width: segmentWidth,
                baselineY: baselineY,
                run: runs[style.runIndex],
                context: &context
            )
        }

        // Advance Y
        context.layout.box.lly = context.layout.box.lly + lineHeight
    }

    /// Style key for batching - avoids repeated property comparisons
    private struct StyleKey: Equatable {
        let runIndex: Int
        let font: PDF.Font
        let fontSize: PDF.UserSpace.Size<1>
        let color: PDF.Color
        let textDecoration: PDF.Annotation.TextMarkup.Kind?
        let verticalOffset: PDF.UserSpace.Height
        let linkURL: String?
        let internalLinkId: String?

        init(run: PDF.Context.Text.Run, index: Int) {
            self.runIndex = index
            self.font = run.font
            self.fontSize = run.fontSize
            self.color = run.color
            self.textDecoration = run.textDecoration
            self.verticalOffset = run.verticalOffset
            self.linkURL = run.linkURL
            self.internalLinkId = run.internalLinkId
        }
    }

    private static func emitSegment(
        bytes: [UInt8],
        at x: PDF.UserSpace.X,
        width: PDF.UserSpace.Width,
        baselineY: PDF.UserSpace.Y,
        run: PDF.Context.Text.Run,
        context: inout PDF.Context
    ) {
        let textY = baselineY - run.verticalOffset

        // Highlight background
        if case .highlight(let annotationColor) = run.textDecoration {
            let fillColor: PDF.Color =
                switch annotationColor {
                case .transparent: .gray(1)
                case .gray(let g): .gray(g)
                case .rgb(let r, let g, let b): .rgb(r: r, g: g, b: b)
                case .cmyk(let c, let m, let y, let k): .cmyk(c: c, m: m, y: y, k: k)
                }
            let bgRect = PDF.UserSpace.Rectangle(
                x: x,
                y: textY - (run.fontSize * 0.85).height,
                width: width,
                height: (run.fontSize * 1.15).height
            )
            context.emit.rectangle(bgRect, fill: fillColor, stroke: nil)
        }

        // Text
        context.emit.text(
            bytes,
            at: PDF.UserSpace.Coordinate(x: x, y: textY),
            font: run.font,
            size: run.fontSize,
            color: run.color
        )

        // Decoration
        if let decoration = run.textDecoration {
            switch decoration {
            case .underline:
                let underlineY = textY + (run.fontSize * 0.15).height
                let lineWidth = max((run.fontSize * 0.05).width, PDF.UserSpace.Width(0.5))
                context.emit.line(
                    from: PDF.UserSpace.Coordinate(x: x, y: underlineY),
                    to: PDF.UserSpace.Coordinate(x: x + width, y: underlineY),
                    color: run.color,
                    width: lineWidth
                )
            case .strikeOut:
                let xHeight = run.font.metrics.xHeight(atSize: run.fontSize)
                let strikeY = textY - xHeight / 2
                let lineWidth = max((run.fontSize * 0.05).width, PDF.UserSpace.Width(0.5))
                context.emit.line(
                    from: PDF.UserSpace.Coordinate(x: x, y: strikeY),
                    to: PDF.UserSpace.Coordinate(x: x + width, y: strikeY),
                    color: run.color,
                    width: lineWidth
                )
            case .highlight, .squiggly:
                break
            }
        }

        // Links
        let linkRect = PDF.UserSpace.Rectangle(
            x: x,
            y: textY - run.fontSize.height * 0.85,
            width: width,
            height: run.fontSize.height * 1.15
        )
        if let internalId = run.internalLinkId {
            context.addPendingInternalLink(rect: linkRect, targetId: internalId)
        } else if let url = run.linkURL {
            context.addLinkAnnotation(rect: linkRect, uri: url)
        }
    }

    private static func emitListMarker(
        _ marker: PDF.Context.List.Marker,
        at markerX: PDF.UserSpace.X,
        context: inout PDF.Context
    ) {
        let markerBaselineY = context.layout.box.lly + context.style.line.ascent
        let baseFont = context.style.font
        let baseFontSize = context.style.fontSize

        switch marker {
        case .text(let bytes, let font):
            context.emit.text(
                bytes,
                at: PDF.UserSpace.Coordinate(x: markerX, y: markerBaselineY),
                font: font,
                size: context.style.fontSize,
                color: context.style.color
            )

        case .strokedCircle(let circle, let strokeWidth):
            let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
            let centerY = markerBaselineY - xHeight * 0.6
            let centerX = markerX + circle.radius
            context.emit.circle(
                center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                radius: circle.radius,
                fill: nil,
                stroke: context.style.color,
                strokeWidth: strokeWidth
            )

        case .filledCircle(let circle):
            let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
            let centerY = markerBaselineY - xHeight / 2
            let centerX = markerX + circle.radius
            context.emit.circle(
                center: PDF.UserSpace.Coordinate(x: centerX, y: centerY),
                radius: circle.radius,
                fill: context.style.color,
                stroke: nil
            )

        case .filledSquare(let square):
            let xHeight = baseFont.metrics.xHeight(atSize: baseFontSize)
            let halfXHeight = xHeight / 2
            let halfSquareHeight = square.height / 2
            let squareY = markerBaselineY - halfXHeight - halfSquareHeight
            let rect = PDF.UserSpace.Rectangle(
                x: markerX,
                y: squareY,
                width: square.width,
                height: square.height
            )
            context.emit.rectangle(rect, fill: context.style.color, stroke: nil)
        }
    }

    // MARK: - ActualText for Copy-Paste

    /// Build the ActualText string from runs for proper copy-paste behavior.
    ///
    /// This combines all runs into a single continuous string, properly handling
    /// spacing between runs with different styles. The ActualText is used by
    /// PDF readers when extracting text for copy-paste operations.
    ///
    /// Performance optimizations (Swift 6.2):
    /// - O(1) boolean tracking instead of O(n) `hasSuffix` checks
    /// - ASCII fast-path (bytes < 0x80) avoids decode table lookup
    /// - Direct UTF-8 buffer building, single String conversion at end
    ///
    /// - Parameter runs: The text runs to combine
    /// - Returns: The combined text with proper spacing
    private static func buildActualText(from runs: [PDF.Context.Text.Run]) -> String {
        // Pre-calculate capacity: total bytes
        // UTF-8 may expand extended chars (0x80-0xFF) to 2-3 bytes
        let totalBytes = runs.reduce(0) { $0 + $1.bytes.count }
        var utf8Buffer: [UInt8] = []
        utf8Buffer.reserveCapacity(totalBytes)

        var lastWasSpace = true  // O(1) tracking for whitespace collapsing

        for run in runs {
            guard !run.bytes.isEmpty else { continue }

            // Process bytes with ASCII fast-path
            for byte in run.bytes {
                if byte.ascii.isWhitespace {
                    // Collapse whitespace to single space
                    if !lastWasSpace {
                        utf8Buffer.append(.ascii.space)
                        lastWasSpace = true
                    }
                } else if byte < 0x80 {
                    // ASCII fast-path: direct passthrough (~95% of English text)
                    utf8Buffer.append(byte)
                    lastWasSpace = false
                } else if let scalar = ISO_32000.WinAnsiEncoding.decode(byte) {
                    // Extended chars (0x80-0xFF): encode to UTF-8
                    for unit in scalar.utf8 {
                        utf8Buffer.append(unit)
                    }
                    lastWasSpace = false
                } else {
                    // Unmapped byte: replace with '?'
                    utf8Buffer.append(0x3F)
                    lastWasSpace = false
                }
            }
        }

        // Single String conversion at end
        return String(decoding: utf8Buffer, as: UTF8.self)
    }
}
