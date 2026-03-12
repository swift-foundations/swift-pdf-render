// PDF.Context.swift
// Rendering context decomposed into categorical primitives.

import Geometry_Primitives
import Layout_Primitives
public import PDF_Standard
public import Copy_on_Write

extension PDF {
    /// Rendering context for PDF layout.
    ///
    /// `Context` is the central state for PDF rendering, decomposed into
    /// orthogonal categorical primitives:
    ///
    /// - **LayoutBox**: Bounded region for content (lattice)
    /// - **Style.Resolved**: Typography and color (product)
    /// - **GraphicsState.Stack**: Save/restore state (state monad)
    /// - **Pagination**: Page management and output accumulation
    ///
    /// ## Coordinate System
    ///
    /// Uses top-left origin with Y increasing downward (matching HTML/CSS).
    /// This is transformed to PDF's bottom-left origin during page creation.
    ///
    /// ## Category-Theoretic Structure
    ///
    /// Context supports composable transformations via `PDF.Context.Transform`:
    /// ```swift
    /// let transform = PDF.Context.Transform
    ///     .font(.helveticaBold)
    ///     .then(.inset(10))
    ///
    /// transform.scoped(in: &context) { ctx in
    ///     // Render with bold font and inset
    /// }
    /// ```
    @CoW
    public struct Context: Sendable {
        // MARK: - Categorical Primitives

        /// The layout box (position + available size).
        public var layoutBox: PDF.UserSpace.Rectangle

        /// Resolved text style.
        public var style: Style.Resolved

        /// Graphics state stack for save/restore operations.
        public var graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState>

        /// Font registry mapping font reference names to Font objects.
        public var fontRegistry: [String: PDF.Font] = [:]

        // MARK: - Inline Text Flow

        /// Accumulated inline text runs.
        public var inlineRuns: [PDF.Context.Text.Run] = []

        // MARK: - List State

        /// Stack of active lists (for nested list support).
        public var listStack: [(type: List.Kind, currentIndex: Int)] = []

        /// Pending list marker to be rendered with the first line of text.
        public var pendingListMarker: (marker: List.Marker, x: PDF.UserSpace.X)?

        // MARK: - Modes

        /// Preformatted mode - preserves whitespace in `<pre>` blocks.
        public var preserveWhitespace: Bool = false

        /// Stack spacing - applied between elements in a VStack.
        public var stackSpacing: PDF.UserSpace.Height?

        /// Track Y position before last element rendered (for spacing logic).
        internal var lastElementY: PDF.UserSpace.Y?

        /// Measurement mode - when true, operations are not added.
        public var measurementMode: Bool = false

        // MARK: - Horizontal Layout

        /// Horizontal stack spacing - applied between elements in an HStack.
        public var horizontalSpacing: PDF.UserSpace.Width?

        // MARK: - Box Model

        /// Top margin (external spacing above element)
        public var marginTop: PDF.UserSpace.Height?

        /// Right margin (external spacing to the right of element)
        public var marginRight: PDF.UserSpace.Width?

        /// Bottom margin (external spacing below element)
        public var marginBottom: PDF.UserSpace.Height?

        /// Left margin (external spacing to the left of element)
        public var marginLeft: PDF.UserSpace.Width?

        /// Top padding (internal spacing at top of element)
        public var paddingTop: PDF.UserSpace.Height?

        /// Right padding (internal spacing at right of element)
        public var paddingRight: PDF.UserSpace.Width?

        /// Bottom padding (internal spacing at bottom of element)
        public var paddingBottom: PDF.UserSpace.Height?

        /// Left padding (internal spacing at left of element)
        public var paddingLeft: PDF.UserSpace.Width?

        /// Explicit width constraint
        public var explicitWidth: PDF.UserSpace.Width?

        /// Explicit height constraint
        public var explicitHeight: PDF.UserSpace.Height?

        /// Track X position before last element rendered (for horizontal spacing).
        internal var lastElementX: PDF.UserSpace.X?

        /// Starting Y position for current horizontal row (to track max height).
        internal var horizontalRowStartY: PDF.UserSpace.Y?

        /// Maximum Y reached in current horizontal row.
        internal var horizontalRowMaxY: PDF.UserSpace.Y?

        // MARK: - Text State (for batching BT/ET blocks)

        /// Whether we're inside a BT (begin text) block.
        internal var textBlockOpen: Bool = false

        /// Current font set in the open text block.
        internal var currentTextFont: PDF.Font?

        /// Current font size set in the open text block.
        internal var currentTextFontSize: PDF.UserSpace.Size<1>?

        /// Current fill color set in the open text block.
        internal var currentTextColor: PDF.Color?

        /// Current text position (PDF coordinates, for relative positioning).
        internal var currentTextPosition: PDF.UserSpace.Coordinate?

        // MARK: - Pagination

        /// Initial layout box (for page reset).
        internal var initialLayoutBox: PDF.UserSpace.Rectangle

        /// Maximum Y position (bottom boundary).
        internal var maxY: PDF.UserSpace.Y

        /// The page's media box (defines page geometry).
        public var mediaBox: ISO_32000.UserSpace.Rectangle

        /// Completed pages (fully built).
        public var completedPages: [PDF.Page] = []

        /// Current page's content stream builder.
        public var currentPageBuilder: ISO_32000.ContentStream.Builder = .init()

        /// Annotations for current page.
        public var currentPageAnnotations: [PDF.Annotation] = []

        /// Pending internal links to be resolved after rendering.
        public var pendingInternalLinks: [PendingInternalLink] = []

        // MARK: - Computed Properties

        /// Page top Y coordinate for coordinate conversion (top-left to bottom-left).
        public var pageTop: PDF.UserSpace.Y {
            mediaBox.ury
        }

        /// A pending internal link that needs to be resolved
        public struct PendingInternalLink: Sendable {
            /// The target anchor id (without #)
            public let targetId: String
            /// Page number where the link is (1-indexed)
            public let pageNumber: Int
            /// Bounds of the link annotation
            public let bounds: PDF.UserSpace.Rectangle

            public init(targetId: String, pageNumber: Int, bounds: PDF.UserSpace.Rectangle) {
                self.targetId = targetId
                self.pageNumber = pageNumber
                self.bounds = bounds
            }
        }
    }
}

// MARK: - Initializers

extension PDF.Context {
    /// Create a render context from primitives.
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
            layoutBox: layoutBox,
            style: style,
            graphicsStack: graphicsStack,
            initialLayoutBox: layoutBox,
            maxY: layoutBox.maxY,
            mediaBox: mediaBox
        )
    }

    /// Create a render context from explicit values.
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

    /// Create context for a page's content area.
    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        margins: PDF.UserSpace.EdgeInsets
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
    ){
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

// MARK: - Position Operations

extension PDF.Context {
    /// Check if we're currently in horizontal layout mode.
    public var isHorizontalLayout: Bool {
        horizontalSpacing != nil
    }

    /// Update the maximum Y reached in the current horizontal row.
    public mutating func updateHorizontalRowMaxY() {
        if let startY = horizontalRowStartY {
            let currentMaxY = horizontalRowMaxY ?? startY
            if layoutBox.lly > currentMaxY {
                horizontalRowMaxY = layoutBox.lly
            }
        }
    }
}

// MARK: - Inline Text Flow

extension PDF.Context {
    /// Append a text run to the inline buffer.
    public mutating func append(inline run: PDF.Context.Text.Run) {
        inlineRuns.append(run)
    }

    /// Check if there are pending inline runs.
    public var hasInlineRuns: Bool {
        !inlineRuns.isEmpty
    }
}

// MARK: - List Context

extension PDF.Context {
    /// Push a new list onto the context stack.
    public mutating func push(list type: List.Kind) {
        let startIndex: Int
        switch type {
        case .unordered:
            startIndex = 0
        case .ordered(let start):
            startIndex = start
        }
        listStack.append((type: type, currentIndex: startIndex))
    }

    /// Pop the current list from the stack.
    public mutating func popList() {
        _ = listStack.popLast()
    }

    /// Get the next list marker and advance the counter.
    ///
    /// Returns a List.Marker for the current list item.
    ///
    /// For unordered lists (matches WebKit/CSS default markers):
    /// - Level 1: • (disc) - filled circle using text bullet
    /// - Level 2: ○ (circle) - stroked (hollow) circle using PDF graphics
    /// - Level 3+: ■ (square) - filled square using PDF graphics
    ///
    /// For ordered lists:
    /// - Numbers with period (1., 2., etc.) in text font
    public mutating func nextListMarker() -> List.Marker {
        guard !listStack.isEmpty else {
            return .text(bytes: [UInt8.WinAnsi.bullet], font: style.font)
        }
        let index = listStack.count - 1
        switch listStack[index].type {
        case .unordered:
            // WebKit uses TOTAL list depth for marker style, not just unordered depth.
            // This means a <ul> nested inside an <ol> at depth 2 gets circle markers.
            let totalDepth = listStack.count
            switch totalDepth {
            case 1:
                // Level 1: • (disc) - use the bullet glyph from the font
                // This produces a properly designed bullet character
                return .text(bytes: [UInt8.WinAnsi.bullet], font: style.font)
            case 2:
                // Level 2: ○ (circle) - hollow circle drawn with PDF graphics
                // Diameter ~0.28em (~80% of level 1) for visual hierarchy
                let radius = (style.fontSize * 0.14).length
                let circle = PDF.UserSpace.Circle(radius: radius)
                // Stroke width proportional to font size (thin stroke for hollow appearance)
                let strokeWidth = (style.fontSize * 0.05).width
                return .strokedCircle(circle, strokeWidth: strokeWidth)
            default:
                // Level 3+: ■ (square) - filled square using PDF graphics
                // Side ~0.22em (~63% of level 1 diameter) for visual hierarchy
                let squareSize = style.fontSize * 0.22
                // Rectangle will be positioned when marker is rendered
                let rect = PDF.UserSpace.Rectangle(
                    x: .init(0),
                    y: .init(0),
                    width: squareSize.width,
                    height: squareSize.height
                )
                return .filledSquare(rect)
            }
        case .ordered:
            let num = listStack[index].currentIndex
            listStack[index].currentIndex += 1
            // WinAnsi encoding for ordered list numbers
            return .text(bytes: [UInt8](winAnsi: "\(num).", withFallback: true), font: style.font)
        }
    }

    /// Returns the current list nesting depth (0 = not in a list).
    public var listDepth: Int {
        listStack.count
    }
}

// MARK: - Pagination

extension PDF.Context {
    /// Add a link annotation to the current page (URI target).
    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        uri: String
    ) {
        let link = PDF.Annotation.Link(uri: uri)
        let annotation = PDF.Annotation(rect: rect, content: .link(link))
        currentPageAnnotations.append(annotation)
    }

    /// Add a link annotation to the current page (internal destination target).
    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        destination: ISO_32000.Destination
    ) {
        let link = PDF.Annotation.Link(destination: destination)
        let annotation = PDF.Annotation(rect: rect, content: .link(link))
        currentPageAnnotations.append(annotation)
    }

    /// Add a pending internal link to be resolved after rendering.
    ///
    /// Internal links (href="#anchor") need to be collected during rendering
    /// and resolved later when all destinations are known.
    public mutating func addPendingInternalLink(
        rect: PDF.UserSpace.Rectangle,
        targetId: String
    ) {
        // Use completedPages.count + 1 for correct 1-indexed page number
        // pages.count includes current page if non-empty, which would overcount
        let pageNumber = completedPages.count + 1
        pendingInternalLinks.append(
            PendingInternalLink(
                targetId: targetId,
                pageNumber: pageNumber,
                bounds: rect
            )
        )
    }

    /// Remaining space on current page.
    public var remainingHeight: PDF.UserSpace.Height {
        .max(.zero, height(maxY - layoutBox.lly))
    }

    /// All pages (completed + current).
    ///
    /// This is the final output of rendering: `[PDF.Page]`
    public var pages: [PDF.Page] {
        var allPages = completedPages
        if !currentPageBuilder.data.isEmpty || textBlockOpen {
            // Build data, appending ET if text block is open
            var data = currentPageBuilder.data
            if textBlockOpen {
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

    /// Resolve pending internal links and return pages with link annotations.
    ///
    /// Internal links (href="#anchor") are collected during rendering and need to be
    /// resolved after all destinations are known. This method:
    /// 1. Takes pages and named destinations
    /// 2. For each pending link, looks up the target destination
    /// 3. Creates link annotations with resolved destinations
    /// 4. Returns modified pages with the link annotations added
    ///
    /// - Parameters:
    ///   - pages: The rendered pages
    ///   - namedDestinations: Dictionary mapping anchor IDs to destination info
    /// - Returns: Pages with resolved internal link annotations
    public static func resolveInternalLinks(
        pages: [PDF.Page],
        pendingLinks: [PendingInternalLink],
        namedDestinations: [String: (pageNumber: Int, yPosition: PDF.UserSpace.Y)]
    ) -> [PDF.Page] {
        guard !pendingLinks.isEmpty else { return pages }

        // Group pending links by page number for efficient processing
        var linksByPage: [Int: [PendingInternalLink]] = [:]
        for link in pendingLinks {
            linksByPage[link.pageNumber, default: []].append(link)
        }

        // Process each page
        return pages.enumerated().map { (index, page) in
            let pageNumber = index + 1  // 1-indexed
            guard let pageLinks = linksByPage[pageNumber], !pageLinks.isEmpty else {
                return page
            }

            // Resolve links for this page
            var newAnnotations = page.annotations
            for pendingLink in pageLinks {
                if let dest = namedDestinations[pendingLink.targetId] {
                    // Create destination pointing to the target page and position
                    // Extract raw Unit from typed Y coordinate for PDF destination
                    let destination = ISO_32000.Destination.xyz(
                        page: dest.pageNumber - 1,  // 0-indexed page reference
                        left: nil,
                        top: dest.yPosition,  // Raw coordinate for PDF user space
                        zoom: nil
                    )
                    let link = PDF.Annotation.Link(destination: destination)
                    let annotation = PDF.Annotation(rect: pendingLink.bounds, content: .link(link))
                    newAnnotations.append(annotation)
                }
            }

            // Return page with updated annotations
            return PDF.Page(
                mediaBox: page.mediaBox,
                contents: page.contents,
                annotations: newAnnotations
            )
        }
    }
}

// MARK: - Measurement

extension PDF.Context {
    /// Execute a closure in measurement mode, returning the height consumed.
    public mutating func measure(
        _ work: (inout PDF.Context) -> Void
    ) -> PDF.UserSpace.Height {
        let startY = layoutBox.lly
        measurementMode = true
        work(&self)
        measurementMode = false
        let measuredHeight: PDF.UserSpace.Height = height(layoutBox.lly - startY)
        layoutBox.lly = startY
        return measuredHeight
    }
}

// MARK: - Color Helpers

extension PDF.Context {
    /// Set the fill color on the current page builder.
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

    /// Set the stroke color on the current page builder.
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
