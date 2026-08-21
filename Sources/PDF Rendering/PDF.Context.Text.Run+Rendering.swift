import ASCII
import Byte_Primitives
import Layout_Primitives
public import PDF_Standard

extension PDF.Context.Text.Run {

    public static func renderRuns(
        _ runs: [PDF.Context.Text.Run],
        context: inout PDF.Context
    ) {
        guard !runs.isEmpty else { return }

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

        let wrapAllowed = !context.mode.noWrap

        var state = RenderState()
        state.lineBytes.reserveCapacity(512)
        state.words.reserveCapacity(32)
        state.currentWord.reserveCapacity(64)

        var currentLineWidth: PDF.UserSpace.Width = .init(0)
        var lastWasWhitespace = !preserveWhitespace
        var isFirstLine = true
        var currentRunIndex = 0

        var cachedSpaceWidth: PDF.UserSpace.Width = .init(0)
        var cachedSpaceFont: PDF.Font?
        var cachedSpaceFontSize: PDF.UserSpace.Size<1>?

        for run in runs {

            if cachedSpaceFont != run.font || cachedSpaceFontSize != run.fontSize {
                cachedSpaceWidth = run.font.winAnsi.width(
                    of: [Byte(UInt8.ascii.space)],
                    atSize: run.fontSize
                )
                cachedSpaceFont = run.font
                cachedSpaceFontSize = run.fontSize
            }

            for byte in run.bytes {

                switch byte.underlying {
                case .ascii.newline:

                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(
                            of: state.currentWord,
                            atSize: run.fontSize
                        )
                        state.appendWord(width: width, runIndex: currentRunIndex)
                        currentLineWidth += width
                    }

                    if !state.words.isEmpty || preserveWhitespace {
                        emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
                        isFirstLine = false
                    }
                    state.clearLine()
                    currentLineWidth = .init(0)
                    lastWasWhitespace = !preserveWhitespace

                case .ascii.space:

                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(
                            of: state.currentWord,
                            atSize: run.fontSize
                        )

                        if state.words.isEmpty {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        } else if !wrapAllowed || currentLineWidth + width <= maxWidth {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth += width
                        } else {

                            emitLine(
                                &state,
                                runs: runs,
                                context: &context,
                                isFirstLine: isFirstLine
                            )
                            isFirstLine = false
                            state.clearLine()
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        }
                        lastWasWhitespace = false
                    }

                    if preserveWhitespace || (!lastWasWhitespace && !state.words.isEmpty) {
                        state.addGap(cachedSpaceWidth)
                        currentLineWidth += cachedSpaceWidth
                    }
                    lastWasWhitespace = true

                case .ascii.htab:

                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(
                            of: state.currentWord,
                            atSize: run.fontSize
                        )
                        if state.words.isEmpty || !wrapAllowed
                            || currentLineWidth + width <= maxWidth
                        {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth += width
                        } else {
                            emitLine(
                                &state,
                                runs: runs,
                                context: &context,
                                isFirstLine: isFirstLine
                            )
                            isFirstLine = false
                            state.clearLine()
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        }
                    }

                    let tabWidth = cachedSpaceWidth * 4
                    if !wrapAllowed || currentLineWidth + tabWidth <= maxWidth {
                        state.addGap(tabWidth)
                        currentLineWidth += tabWidth
                    }
                    lastWasWhitespace = true

                default:
                    state.currentWord.append(byte)
                }
            }

            if !state.currentWord.isEmpty {
                let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)
                if state.words.isEmpty {
                    state.appendWord(width: width, runIndex: currentRunIndex)
                    currentLineWidth = width
                } else if !wrapAllowed || currentLineWidth + width <= maxWidth {
                    state.appendWord(width: width, runIndex: currentRunIndex)
                    currentLineWidth += width
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

        if !state.words.isEmpty {
            emitLine(&state, runs: runs, context: &context, isFirstLine: isFirstLine)
        }
    }

    private struct RenderState {

        var lineBytes: [Byte] = []

        var words: [WordDescriptor] = []

        var currentWord: [Byte] = []

        mutating func appendWord(width: PDF.UserSpace.Width, runIndex: Int) {
            let start = lineBytes.count
            lineBytes.append(contentsOf: currentWord)
            words.append(
                WordDescriptor(
                    byteStart: start,
                    byteLength: currentWord.count,
                    width: width,
                    gapAfter: .init(0),
                    runIndex: runIndex
                )
            )
            currentWord.removeAll(keepingCapacity: true)
        }

        mutating func addGap(_ width: PDF.UserSpace.Width) {
            if !words.isEmpty {
                words[words.count - 1].gapAfter += width
            }
        }

        mutating func clearLine() {
            lineBytes.removeAll(keepingCapacity: true)
            words.removeAll(keepingCapacity: true)
        }
    }

    private struct WordDescriptor {
        let byteStart: Int
        let byteLength: Int
        let width: PDF.UserSpace.Width
        var gapAfter: PDF.UserSpace.Width
        let runIndex: Int
    }

    private static func emitLine(
        _ state: inout RenderState,
        runs: [PDF.Context.Text.Run],
        context: inout PDF.Context,
        isFirstLine: Bool
    ) {
        guard !state.words.isEmpty else { return }

        let lineHeight = context.style.line.height
        context.page.ensure(height: lineHeight)

        if isFirstLine, let pending = context.list.marker {
            emitListMarker(pending.marker, at: pending.x, context: &context)
            context.list.marker = nil
        }

        let baselineY = context.layout.box.lly + context.style.line.ascent

        var totalWidth: PDF.UserSpace.Width = .init(0)
        (0..<state.words.count).forEach { i in
            totalWidth += state.words[i].width
            if i < state.words.count - 1 {
                totalWidth += state.words[i].gapAfter
            }
        }

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

        var segmentBytes: [Byte] = []
        segmentBytes.reserveCapacity(256)
        var segmentStartX = currentX
        var segmentWidth: PDF.UserSpace.Width = .init(0)
        var currentStyle: StyleKey?

        for word in state.words {
            let run = runs[word.runIndex]

            let wordStyle = StyleKey(run: run, index: word.runIndex)

            if let current = currentStyle, current != wordStyle {

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

            let wordBytes = state.lineBytes[word.byteStart..<(word.byteStart + word.byteLength)]
            segmentBytes.append(contentsOf: wordBytes)
            segmentWidth += word.width
            currentStyle = wordStyle

            currentX += word.width

            if word.gapAfter > .init(0) {

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
                currentX += word.gapAfter
                segmentStartX = currentX
                segmentWidth = .init(0)
            }
        }

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

        context.layout.box.lly += lineHeight
    }

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
        bytes: [Byte],
        at x: PDF.UserSpace.X,
        width: PDF.UserSpace.Width,
        baselineY: PDF.UserSpace.Y,
        run: PDF.Context.Text.Run,
        context: inout PDF.Context
    ) {
        let textY = baselineY - run.verticalOffset

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

        context.emit.text(
            bytes,
            at: PDF.UserSpace.Coordinate(x: x, y: textY),
            font: run.font,
            size: run.fontSize,
            color: run.color
        )

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

    private static func buildActualText(from runs: [PDF.Context.Text.Run]) -> String {

        let totalBytes = runs.reduce(0) { $0 + $1.bytes.count }
        var utf8Buffer: [UInt8] = []
        utf8Buffer.reserveCapacity(totalBytes)

        var lastWasSpace = true

        for run in runs {
            guard !run.bytes.isEmpty else { continue }

            for byte in run.bytes {
                if byte.underlying.ascii.isWhitespace {

                    if !lastWasSpace {
                        utf8Buffer.append(.ascii.space)
                        lastWasSpace = true
                    }
                } else if byte < 0x80 {

                    utf8Buffer.append(byte.underlying)
                    lastWasSpace = false
                } else if let scalar = ISO_32000.WinAnsiEncoding.decode(byte) {

                    for unit in scalar.utf8 {
                        utf8Buffer.append(unit)
                    }
                    lastWasSpace = false
                } else {

                    utf8Buffer.append(0x3F)
                    lastWasSpace = false
                }
            }
        }

        return String(decoding: utf8Buffer, as: UTF8.self)
    }
}
