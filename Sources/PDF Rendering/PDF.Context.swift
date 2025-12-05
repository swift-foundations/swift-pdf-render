// PDF.Context.swift

public import PDF_Standard

extension PDF {
    /// Rendering context for PDF layout
    ///
    /// Tracks current position, available dimensions, and styling
    /// for layout views to use when generating content operations.
    ///
    /// Uses top-left origin with y increasing downward (matching HTML/CSS).
    public struct Context: Sendable {
        /// Current X position (from left edge)
        public var x: UserSpace.X

        /// Current Y position (from top edge)
        public var y: UserSpace.Y

        /// Available width for content
        public var availableWidth: UserSpace.Width

        /// Available height for content
        public var availableHeight: UserSpace.Height

        /// Current font
        public var font: PDF.Font

        /// Current font size in points
        public var fontSize: UserSpace.Unit

        /// Current text color
        public var color: PDF.Color

        /// Line height multiplier
        public var lineHeight: Double

        /// Current text decoration (underline, strikethrough)
        public var textDecoration: PDF.TextDecoration = .none

        /// Current text background color for highlighting
        public var textBackgroundColor: PDF.Color? = nil

        /// Accumulated inline text runs (for inline flow)
        ///
        /// Block elements flush this buffer to render accumulated inline content
        /// as a single wrapped unit. Inline elements append to it without rendering.
        public var inlineRuns: [PDF.TextRun] = []

        /// Stack of active lists (for nested list support)
        public var listStack: [(type: ListType, currentIndex: Int)] = []

        /// Preformatted mode - preserves whitespace in `<pre>` blocks
        public var preserveWhitespace: Bool = false

        /// Stack spacing - applied between elements in a VStack
        /// When non-nil, elements should advance by this amount after rendering
        public var stackSpacing: PDF.UserSpace.Y? = nil

        /// Track Y position before last element rendered (for spacing logic)
        internal var lastElementY: PDF.UserSpace.Y? = nil

        // MARK: - Pagination Support

        /// Initial X position (left margin)
        private var initialX: UserSpace.X

        /// Initial Y position (top margin)
        private var initialY: UserSpace.Y

        /// Maximum Y position (bottom boundary = top margin + content height)
        private var maxY: UserSpace.Y

        /// Operations for completed pages
        public var completedPages: [[PDF.Render.Operation]] = []

        /// Operations for current page
        public var currentPageOperations: [PDF.Render.Operation] = []

        /// Annotations for completed pages
        public var completedPageAnnotations: [[PDF.Annotation]] = []

        /// Annotations for current page
        public var currentPageAnnotations: [PDF.Annotation] = []

        // MARK: - Measurement Mode

        /// When true, add() operations are suppressed (for measuring content height).
        ///
        /// In measurement mode, the context still tracks Y position advancement
        /// but doesn't commit operations to `currentPageOperations`. This allows
        /// measuring how much vertical space content would consume without
        /// actually rendering it.
        public var measurementMode: Bool = false
    }
}

extension PDF.Context {
    // MARK: - List Context

    /// Type of list being rendered
    public enum ListType: Sendable {
        case unordered
        case ordered(startNumber: Int)
    }
}

extension PDF.Context {
    /// Create a render context
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
        self.x = x
        self.y = y
        self.initialX = x
        self.initialY = y
        self.maxY = .init(y.value + availableHeight.value)
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight
        self.font = font
        self.fontSize = fontSize
        self.color = color
        self.lineHeight = lineHeight
    }

    /// Create context for a page's content area
    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        margins: PDF.UserSpace.EdgeInsets
    ) {
        let contentWidth = PDF.UserSpace.Width(mediaBox.width.value - margins.horizontal)
        let contentHeight = PDF.UserSpace.Height(mediaBox.height.value - margins.vertical)
        self.x = PDF.UserSpace.X(margins.leading)
        self.y = PDF.UserSpace.Y(margins.top)
        self.initialX = PDF.UserSpace.X(margins.leading)
        self.initialY = PDF.UserSpace.Y(margins.top)
        self.maxY = PDF.UserSpace.Y(margins.top + contentHeight.value)
        self.availableWidth = contentWidth
        self.availableHeight = contentHeight
        self.font = .helvetica
        self.fontSize = 12
        self.color = .black
        self.lineHeight = 1.2
    }
}

extension PDF.Context {
    /// Line height in points
    public var lineHeightPoints: PDF.UserSpace.Unit {
        fontSize * lineHeight
    }
}

extension PDF.Context {
    /// Advance Y position by one line
    public mutating func advanceLine() {
        y = PDF.UserSpace.Y(PDF.UserSpace.Unit(y.value) + lineHeightPoints)
    }

    /// Advance Y position by specified amount
    public mutating func advance(_ amount: PDF.UserSpace.Y) {
        y = PDF.UserSpace.Y(y.value + amount.value)
    }

    // MARK: - Inline Text Flow

    /// Append a text run to the inline buffer.
    ///
    /// Text runs accumulate until a block element flushes them.
    /// This enables proper inline flow with mixed styling.
    public mutating func appendInlineRun(_ run: PDF.TextRun) {
        inlineRuns.append(run)
    }

    /// Flush accumulated inline runs, rendering them as a wrapped block.
    ///
    /// Call this at the end of block elements (p, div, h1-h6, etc.)
    /// to render accumulated inline content with proper line wrapping.
    ///
    /// - Returns: PDF content operations for the flushed text
    public mutating func flushInlineRuns() -> PDF.Content {
        guard !inlineRuns.isEmpty else { return PDF.Content() }
        let runs = inlineRuns
        inlineRuns = []
        return PDF.TextRun.renderRuns(runs, context: &self)
    }

    /// Check if there are pending inline runs
    public var hasInlineRuns: Bool {
        !inlineRuns.isEmpty
    }

    // MARK: - List Context Management

    /// Push a new list onto the context stack
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

    /// Pop the current list from the stack
    public mutating func popList() {
        _ = listStack.popLast()
    }

    /// Get the next list marker and advance the counter
    ///
    /// Returns `-` for unordered lists, `1.`, `2.`, etc. for ordered lists.
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

    /// Start a new page, saving current operations
    public mutating func startNewPage() {
        // Save current page operations and annotations
        completedPages.append(currentPageOperations)
        completedPageAnnotations.append(currentPageAnnotations)
        currentPageOperations = []
        currentPageAnnotations = []

        // Reset position to top of page
        y = initialY
        x = initialX
    }

    /// Add operation to current page
    ///
    /// When `measurementMode` is true, operations are not added (for height measurement).
    public mutating func add(_ operation: PDF.Render.Operation) {
        guard !measurementMode else { return }
        currentPageOperations.append(operation)
    }

    /// Add multiple operations to current page
    ///
    /// When `measurementMode` is true, operations are not added (for height measurement).
    public mutating func add(_ operations: [PDF.Render.Operation]) {
        guard !measurementMode else { return }
        currentPageOperations.append(contentsOf: operations)
    }

    /// Add a link annotation to the current page
    public mutating func addLinkAnnotation(
        rect: PDF.UserSpace.Rectangle,
        uri: String
    ) {
        currentPageAnnotations.append(.link(ISO_32000.LinkAnnotation(rect: rect, uri: uri)))
    }

    /// Check if we need a page break and start new page if so
    ///
    /// Call this before rendering content that requires `height` space.
    /// Returns true if a new page was started.
    @discardableResult
    public mutating func checkPageBreak(needing height: PDF.UserSpace.Height) -> Bool {
        if wouldExceedPage(adding: height) {
            startNewPage()
            return true
        }
        return false
    }
}

extension PDF.Context {
    // MARK: - Pagination

    /// Check if adding the given height would exceed the page boundary
    public func wouldExceedPage(adding height: PDF.UserSpace.Height) -> Bool {
        y.value + height.value > maxY.value
    }

    /// Remaining space on current page
    public var remainingHeight: PDF.UserSpace.Height {
        let remaining = PDF.UserSpace.Height(maxY.value - y.value)
        return remaining.value > 0 ? remaining : .zero
    }

    /// Get all pages' operations (completed + current)
    public func getAllPages() -> [[PDF.Render.Operation]] {
        var allPages = completedPages
        if !currentPageOperations.isEmpty {
            allPages.append(currentPageOperations)
        }
        return allPages
    }

    /// Get all pages' annotations (completed + current)
    public func getAllAnnotations() -> [[PDF.Annotation]] {
        var allAnnotations = completedPageAnnotations
        // Ensure same count as pages
        while allAnnotations.count < completedPages.count {
            allAnnotations.append([])
        }
        allAnnotations.append(currentPageAnnotations)
        return allAnnotations
    }

    // MARK: - Measurement

    /// Execute a closure in measurement mode, returning the height consumed.
    ///
    /// In measurement mode, Y position advances but operations are not added to
    /// `currentPageOperations`. This allows measuring content height without rendering.
    ///
    /// - Parameter work: The work to execute in measurement mode
    /// - Returns: The height consumed during the measurement
    public mutating func measure(_ work: (inout PDF.Context) -> Void) -> PDF.UserSpace.Height {
        let startY = y
        measurementMode = true
        work(&self)
        measurementMode = false
        let height = PDF.UserSpace.Height(y.value - startY.value)
        y = startY  // Reset Y position
        return height
    }
}
