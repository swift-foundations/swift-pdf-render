import Byte_Primitives
public import Copy_on_Write
import Geometry_Primitives
import Layout_Primitives
public import PDF_Standard

extension PDF {

    @CoW
    public struct Context: Sendable {

        public var layout: Layout

        public var style: Style.Resolved

        public var margin: Margin = .init()

        public var padding: Padding = .init()

        public var constraint: Constraint = .init()

        public var spacing: Spacing = .init()

        public var inline: Inline = .init()

        public var list: List.State = .init()

        public var link: Link = .init()

        public var mode: Mode = .init()

        internal var text: Text.State = .init()

        internal var row: Row = .init()

        public var graphics: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState>

        public var fonts: [String: PDF.Font] = [:]

        internal var lastY: PDF.UserSpace.Y?

        internal var scopes: [Scope] = []

        public var mediaBox: ISO_32000.UserSpace.Rectangle

        public var completedPages: [PDF.Page] = []

        public var currentPageBuilder: ISO_32000.ContentStream.Builder = .init()

        public var currentPageAnnotations: [PDF.Annotation] = []
    }
}

extension PDF.Context {

    public var pageTop: PDF.UserSpace.Y {
        mediaBox.ury
    }
}

extension PDF.Context {

    public init(
        layoutBox: PDF.UserSpace.Rectangle,
        mediaBox: ISO_32000.UserSpace.Rectangle,
        style: Style.Resolved = .init(
            font: .helvetica,
            fontSize: 12,
            color: .black,
            lineHeight: 1.2
        ),
        graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState> = .init(
            initial: .init()
        )
    ) {
        self.init(
            layout: Layout(box: layoutBox, initial: layoutBox, maxY: layoutBox.maxY),
            style: style,
            graphics: graphicsStack,
            mediaBox: mediaBox
        )
    }

    public init(
        x: PDF.UserSpace.X = .init(0),
        y: PDF.UserSpace.Y = .init(0),
        availableWidth: PDF.UserSpace.Width,
        availableHeight: PDF.UserSpace.Height,
        mediaBox: ISO_32000.UserSpace.Rectangle,
        font: PDF.Font = .helvetica,
        fontSize: PDF.UserSpace.Size<1> = 12,
        color: PDF.Color = .black,
        lineHeight: Scale<1, Double> = 1.2
    ) {
        let box = PDF.UserSpace.Rectangle(
            x: x,
            y: y,
            width: availableWidth,
            height: availableHeight
        )
        self.init(
            layoutBox: box,
            mediaBox: mediaBox,
            style: .init(
                font: font,
                fontSize: fontSize,
                color: color,
                lineHeight: lineHeight
            )
        )
    }

    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        margins: PDF.UserSpace.Insets
    ) {
        let contentWidth = mediaBox.width - margins.horizontal
        let contentHeight = mediaBox.height - margins.vertical
        self.init(
            x: .zero + margins.leading,
            y: .zero + margins.top,
            availableWidth: contentWidth,
            availableHeight: contentHeight,
            mediaBox: mediaBox
        )
    }
}

extension PDF.Context {
    public init(
        _ configuration: PDF.Configuration
    ) {
        let contentWidth = configuration.mediaBox.width - configuration.margins.horizontal
        let contentHeight = configuration.mediaBox.height - configuration.margins.vertical

        self = PDF.Context(
            x: .zero + configuration.margins.leading,
            y: .zero + configuration.margins.top,
            availableWidth: contentWidth,
            availableHeight: contentHeight,
            mediaBox: configuration.mediaBox,
            font: configuration.defaultFont,
            fontSize: configuration.defaultFontSize,
            color: configuration.defaultColor,
            lineHeight: configuration.lineHeight
        )
    }
}

extension PDF.Context {

    public mutating func updateRowMaxY() {
        if let startY = row.startY {
            let currentMaxY = row.maxY ?? startY
            if layout.box.lly > currentMaxY {
                row.maxY = layout.box.lly
            }
        }
    }
}

extension PDF.Context {

    public mutating func append(inline run: PDF.Context.Text.Run) {
        self.inline.runs.append(run)
    }
}

extension PDF.Context {

    public mutating func push(list type: List.Kind) {
        let startIndex: Int
        switch type {
        case .unordered:
            startIndex = 0

        case .ordered(let start):
            startIndex = start
        }
        list.stack.append((type: type, currentIndex: startIndex))
    }

    public mutating func nextListMarker() -> List.Marker {
        guard !list.stack.isEmpty else {
            return .text(bytes: [Byte.WinAnsi.bullet], font: style.font)
        }
        let index = list.stack.count - 1
        switch list.stack[index].type {
        case .unordered:

            let totalDepth = list.stack.count
            switch totalDepth {
            case 1:

                return .text(bytes: [Byte.WinAnsi.bullet], font: style.font)

            case 2:

                let radius = (style.fontSize * 0.14).length
                let circle = PDF.UserSpace.Circle(radius: radius)

                let strokeWidth = (style.fontSize * 0.05).width
                return .strokedCircle(circle, strokeWidth: strokeWidth)

            default:

                let squareSize = style.fontSize * 0.22

                let rect = PDF.UserSpace.Rectangle(
                    x: .init(0),
                    y: .init(0),
                    width: squareSize.width,
                    height: squareSize.height
                )
                return .filledSquare(rect)
            }

        case .ordered:
            let num = list.stack[index].currentIndex
            list.stack[index].currentIndex += 1

            return .text(bytes: [Byte](winAnsi: "\(num).", withFallback: true), font: style.font)
        }
    }
}

extension PDF.Context {

    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        uri: String
    ) {
        let link = PDF.Annotation.Link(uri: uri)
        let annotation = PDF.Annotation(rect: rect, content: .link(link))
        currentPageAnnotations.append(annotation)
    }

    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        destination: ISO_32000.Destination
    ) {
        let link = PDF.Annotation.Link(destination: destination)
        let annotation = PDF.Annotation(rect: rect, content: .link(link))
        currentPageAnnotations.append(annotation)
    }

    public mutating func addPendingInternalLink(
        rect: PDF.UserSpace.Rectangle,
        targetId: String
    ) {

        let pageNumber = completedPages.count + 1
        link.pending.append(
            Link.Pending(
                targetId: targetId,
                pageNumber: pageNumber,
                bounds: rect
            )
        )
    }

    public var remainingHeight: PDF.UserSpace.Height {
        .max(.zero, height(layout.maxY - layout.box.lly))
    }

    public var pages: [PDF.Page] {
        var allPages = completedPages
        if !currentPageBuilder.data.isEmpty || text.blockOpen {

            var data = currentPageBuilder.data
            if text.blockOpen {
                if !data.isEmpty {
                    data.append(.ascii.lf)
                }
                data.append(contentsOf: [UInt8]("ET".utf8))
            }
            let currentStream = ISO_32000.ContentStream(
                data: data,
                fontsUsed: currentPageBuilder.fontsUsed,
                imagesUsed: currentPageBuilder.imagesUsed
            )
            let currentPage = PDF.Page(
                mediaBox: mediaBox,
                contentStream: currentStream,
                annotations: currentPageAnnotations
            )
            allPages.append(currentPage)
        }
        return allPages
    }

    public static func resolveInternalLinks(
        pages: [PDF.Page],
        pendingLinks: [Link.Pending],
        namedDestinations: [String: (pageNumber: Int, yPosition: PDF.UserSpace.Y)]
    ) -> [PDF.Page] {
        guard !pendingLinks.isEmpty else { return pages }

        var linksByPage: [Int: [Link.Pending]] = [:]
        for link in pendingLinks {
            linksByPage[link.pageNumber, default: []].append(link)
        }

        return pages.enumerated().map { index, page in
            let pageNumber = index + 1
            guard let pageLinks = linksByPage[pageNumber], !pageLinks.isEmpty else {
                return page
            }

            var newAnnotations = page.annotations
            for pendingLink in pageLinks {
                if let dest = namedDestinations[pendingLink.targetId] {

                    let destination = ISO_32000.Destination.xyz(
                        page: dest.pageNumber - 1,
                        left: nil,
                        top: dest.yPosition,
                        zoom: nil
                    )
                    let link = PDF.Annotation.Link(destination: destination)
                    let annotation = PDF.Annotation(rect: pendingLink.bounds, content: .link(link))
                    newAnnotations.append(annotation)
                }
            }

            return PDF.Page(
                mediaBox: page.mediaBox,
                contents: page.contents,
                annotations: newAnnotations
            )
        }
    }
}

extension PDF.Context {

    public mutating func measure(
        _ work: (inout PDF.Context) -> Void
    ) -> PDF.UserSpace.Height {
        let saved = self
        mode.measurement = true
        mode.pageBreaks = 0
        let startY = layout.box.lly
        work(&self)
        let endY = layout.box.lly
        let breaks = mode.pageBreaks
        let measuredHeight: PDF.UserSpace.Height
        if breaks == 0 {
            measuredHeight = height(endY - startY)
        } else {

            var total = height(layout.maxY - startY) + height(endY - layout.initial.lly)
            for _ in 1..<breaks {
                total += height(layout.maxY - layout.initial.lly)
            }
            measuredHeight = total
        }
        self = saved
        return measuredHeight
    }
}

extension PDF.Context {

    internal mutating func setFillColor(_ color: PDF.Color) {
        switch color {
        case .gray(let g):
            currentPageBuilder.setFillColorGray(g)

        case .rgb(let r, let g, let b):
            currentPageBuilder.setFillColorRGB(r: r, g: g, b: b)

        case .cmyk(let c, let m, let y, let k):
            currentPageBuilder.setFillColorCMYK(c: c, m: m, y: y, k: k)
        }
    }

    internal mutating func setStrokeColor(_ color: PDF.Color) {
        switch color {
        case .gray(let g):
            currentPageBuilder.setStrokeColorGray(g)

        case .rgb(let r, let g, let b):
            currentPageBuilder.setStrokeColorRGB(r: r, g: g, b: b)

        case .cmyk(let c, let m, let y, let k):
            currentPageBuilder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
        }
    }
}
