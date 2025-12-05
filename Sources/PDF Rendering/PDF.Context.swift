// PDF.Context.swift
// Rendering context decomposed into categorical primitives.

public import PDF_Standard

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
    public struct Context: Sendable {
        // MARK: - Categorical Primitives

        /// The layout box (position + available size).
        ///
        /// Forms a bounded lattice under intersection.
        public var layoutBox: PDF.LayoutBox

        /// Resolved text style.
        ///
        /// Forms a monoid under combination.
        public var style: PDF.Style.Resolved

        /// Graphics state stack for save/restore operations.
        ///
        /// Mirrors ISO 32000's q/Q operators.
        public var graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState>

        // MARK: - Inline Text Flow

        /// Accumulated inline text runs.
        ///
        /// Block elements flush this buffer to render accumulated inline content
        /// as a single wrapped unit. Inline elements append without rendering.
        public var inlineRuns: [PDF.Text.Run] = []

        // MARK: - List State

        /// Stack of active lists (for nested list support).
        public var listStack: [(type: ListType, currentIndex: Int)] = []

        // MARK: - Modes

        /// Preformatted mode - preserves whitespace in `<pre>` blocks.
        public var preserveWhitespace: Bool = false

        /// Stack spacing - applied between elements in a VStack.
        public var stackSpacing: PDF.UserSpace.Y? = nil

        /// Track Y position before last element rendered (for spacing logic).
        internal var lastElementY: PDF.UserSpace.Y? = nil

        /// Measurement mode - when true, operations are not added.
        public var measurementMode: Bool = false

        // MARK: - Pagination

        /// Initial layout box (for page reset).
        private var initialLayoutBox: PDF.LayoutBox

        /// Maximum Y position (bottom boundary).
        private var maxY: PDF.UserSpace.Y

        /// Operations for completed pages.
        public var completedPages: [[PDF.Render.Operation]] = []

        /// Operations for current page.
        public var currentPageOperations: [PDF.Render.Operation] = []

        /// Annotations for completed pages.
        public var completedPageAnnotations: [[PDF.Annotation]] = []

        /// Annotations for current page.
        public var currentPageAnnotations: [PDF.Annotation] = []
    }
}



// MARK: - Initializers

extension PDF.Context {
    /// Create a render context from primitives.
    public init(
        layoutBox: PDF.LayoutBox,
        style: PDF.Style.Resolved = .init(
            font: .helvetica,
            fontSize: 12,
            color: .black,
            lineHeight: 1.2
        ),
        graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState> = .init(initial: .init())
    ) {
        self.layoutBox = layoutBox
        self.style = style
        self.graphicsStack = graphicsStack
        self.initialLayoutBox = layoutBox
        self.maxY = layoutBox.maxY
    }

    /// Create a render context from explicit values.
    public init(
        x: PDF.UserSpace.X = 0,
        y: PDF.UserSpace.Y = 0,
        availableWidth: PDF.UserSpace.Width,
        availableHeight: PDF.UserSpace.Height,
        font: PDF.Font = .helvetica,
        fontSize: PDF.UserSpace.Unit = 12,
        color: PDF.Color = .black,
        lineHeight: Double = 1.2
    ) {
        let box = PDF.LayoutBox(
            x: x, y: y,
            width: availableWidth,
            height: availableHeight
        )
        self.init(
            layoutBox: box,
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
        let contentWidth = PDF.UserSpace.Width(mediaBox.width.value - margins.horizontal)
        let contentHeight = PDF.UserSpace.Height(mediaBox.height.value - margins.vertical)
        self.init(
            x: PDF.UserSpace.X(margins.leading),
            y: PDF.UserSpace.Y(margins.top),
            availableWidth: contentWidth,
            availableHeight: contentHeight
        )
    }
}

// MARK: - Backward-Compatible Accessors

extension PDF.Context {
    /// Current X position (from left edge).
    @inlinable
    public var x: PDF.UserSpace.X {
        get { layoutBox.x }
        set { layoutBox.x = newValue }
    }

    /// Current Y position (from top edge).
    @inlinable
    public var y: PDF.UserSpace.Y {
        get { layoutBox.y }
        set { layoutBox.y = newValue }
    }

    /// Available width for content.
    @inlinable
    public var availableWidth: PDF.UserSpace.Width {
        get { layoutBox.width }
        set { layoutBox.width = newValue }
    }

    /// Available height for content.
    @inlinable
    public var availableHeight: PDF.UserSpace.Height {
        get { layoutBox.height }
        set { layoutBox.height = newValue }
    }

    /// Current font.
    @inlinable
    public var font: PDF.Font {
        get { style.font }
        set { style.font = newValue }
    }

    /// Current font size in points.
    @inlinable
    public var fontSize: PDF.UserSpace.Unit {
        get { style.fontSize }
        set { style.fontSize = newValue }
    }

    /// Current text color.
    @inlinable
    public var color: PDF.Color {
        get { style.color }
        set { style.color = newValue }
    }

    /// Line height multiplier.
    @inlinable
    public var lineHeight: Double {
        get { style.lineHeight }
        set { style.lineHeight = newValue }
    }

    /// Current text decoration.
    @inlinable
    public var textMarkup: PDF.TextMarkup? {
        get { style.textMarkup }
        set { style.textMarkup = newValue }
    }

    /// Line height in points.
    @inlinable
    public var lineHeightPoints: PDF.UserSpace.Unit {
        style.lineHeightPoints
    }
}

// MARK: - Position Operations

extension PDF.Context {
    /// Advance Y position by one line.
    public mutating func advanceLine() {
        layoutBox.y = PDF.UserSpace.Y(PDF.UserSpace.Unit(layoutBox.y.value.value + lineHeightPoints.value))
    }

    /// Advance Y position by specified amount.
    public mutating func advance(_ amount: PDF.UserSpace.Y) {
        layoutBox.y = PDF.UserSpace.Y(layoutBox.y.value + amount.value)
    }
}

// MARK: - Inline Text Flow

extension PDF.Context {
    /// Append a text run to the inline buffer.
    public mutating func append(inline run: PDF.Text.Run) {
        inlineRuns.append(run)
    }

    /// Flush accumulated inline runs, rendering them as a wrapped block.
    ///
    /// - Returns: PDF content operations for the flushed text
    public mutating func flushInlineRuns() -> PDF.Content {
        guard !inlineRuns.isEmpty else { return PDF.Content() }
        let runs = inlineRuns
        inlineRuns = []
        return PDF.Text.Run.renderRuns(runs, context: &self)
    }

    /// Check if there are pending inline runs.
    public var hasInlineRuns: Bool {
        !inlineRuns.isEmpty
    }
}

// MARK: - List Context

extension PDF.Context {
    /// Push a new list onto the context stack.
    public mutating func push(list type: ListType) {
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
    public mutating func nextListMarker() -> String {
        guard !listStack.isEmpty else { return "-" }
        let index = listStack.count - 1
        switch listStack[index].type {
        case .unordered:
            return "-"
        case .ordered:
            let num = listStack[index].currentIndex
            listStack[index].currentIndex += 1
            return "\(num)."
        }
    }
}

// MARK: - Pagination

extension PDF.Context {
    /// Start a new page, saving current operations.
    public mutating func startNewPage() {
        completedPages.append(currentPageOperations)
        completedPageAnnotations.append(currentPageAnnotations)
        currentPageOperations = []
        currentPageAnnotations = []

        // Reset to initial layout position
        layoutBox.origin = initialLayoutBox.origin
    }

    /// Add operation to current page.
    public mutating func add(_ operation: PDF.Render.Operation) {
        guard !measurementMode else { return }
        currentPageOperations.append(operation)
    }

    /// Add multiple operations to current page.
    public mutating func add(_ operations: [PDF.Render.Operation]) {
        guard !measurementMode else { return }
        currentPageOperations.append(contentsOf: operations)
    }

    /// Add a link annotation to the current page.
    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        uri: String
    ) {
        currentPageAnnotations.append(.link(ISO_32000.LinkAnnotation(rect: rect, uri: uri)))
    }

    /// Check if we need a page break and start new page if so.
    @discardableResult
    public mutating func checkPageBreak(needing height: PDF.UserSpace.Height) -> Bool {
        if wouldExceedPage(adding: height) {
            startNewPage()
            return true
        }
        return false
    }

    /// Check if adding the given height would exceed the page boundary.
    public func wouldExceedPage(adding height: PDF.UserSpace.Height) -> Bool {
        layoutBox.y.value + height.value > maxY.value
    }

    /// Remaining space on current page.
    public var remainingHeight: PDF.UserSpace.Height {
        let remaining = PDF.UserSpace.Height(maxY.value - layoutBox.y.value)
        return remaining.value > 0 ? remaining : .zero
    }

    /// Get all pages' operations (completed + current).
    public func getAllPages() -> [[PDF.Render.Operation]] {
        var allPages = completedPages
        if !currentPageOperations.isEmpty {
            allPages.append(currentPageOperations)
        }
        return allPages
    }

    /// Get all pages' annotations (completed + current).
    public func getAllAnnotations() -> [[PDF.Annotation]] {
        var allAnnotations = completedPageAnnotations
        while allAnnotations.count < completedPages.count {
            allAnnotations.append([])
        }
        allAnnotations.append(currentPageAnnotations)
        return allAnnotations
    }
}

// MARK: - Measurement

extension PDF.Context {
    /// Execute a closure in measurement mode, returning the height consumed.
    public mutating func measure(_ work: (inout PDF.Context) -> Void) -> PDF.UserSpace.Height {
        let startY = layoutBox.y
        measurementMode = true
        work(&self)
        measurementMode = false
        let height = PDF.UserSpace.Height(layoutBox.y.value - startY.value)
        layoutBox.y = startY
        return height
    }
}

// MARK: - Transform Application

extension PDF.Context {
    /// Apply a transform to this context, returning the result.
    public func applying(_ transform: Transform) -> PDF.Context {
        transform.apply(to: self)
    }

    /// Apply a transform to this context in-place.
    public mutating func apply(_ transform: Transform) {
        transform.apply(to: &self)
    }

    /// Execute a closure with a transform applied, then restore original state.
    @discardableResult
    public mutating func withTransform<T>(
        _ transform: Transform,
        _ body: (inout PDF.Context) throws -> T
    ) rethrows -> T {
        try transform.scoped(in: &self, body)
    }
}
