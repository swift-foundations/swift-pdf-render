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
        public var x: Double

        /// Current Y position (from top edge)
        public var y: Double

        /// Available width for content
        public var availableWidth: Double

        /// Available height for content
        public var availableHeight: Double

        /// Current font
        public var font: PDF.Font

        /// Current font size in points
        public var fontSize: Double

        /// Current text color
        public var color: PDF.Color

        /// Line height multiplier
        public var lineHeight: Double

        /// Accumulated inline text runs (for inline flow)
        ///
        /// Block elements flush this buffer to render accumulated inline content
        /// as a single wrapped unit. Inline elements append to it without rendering.
        public var inlineRuns: [PDF.TextRun] = []

        // MARK: - Pagination Support

        /// Initial X position (left margin)
        private var initialX: Double

        /// Initial Y position (top margin)
        private var initialY: Double

        /// Maximum Y position (bottom boundary = top margin + content height)
        private var maxY: Double

        /// Operations for completed pages
        public var completedPages: [[PDF.Operation]] = []

        /// Operations for current page
        public var currentPageOperations: [PDF.Operation] = []

        /// Create a render context
        public init(
            x: Double = 0,
            y: Double = 0,
            availableWidth: Double,
            availableHeight: Double,
            font: PDF.Font = .helvetica,
            fontSize: Double = 12,
            color: PDF.Color = .black,
            lineHeight: Double = 1.2
        ) {
            self.x = x
            self.y = y
            self.initialX = x
            self.initialY = y
            self.maxY = y + availableHeight
            self.availableWidth = availableWidth
            self.availableHeight = availableHeight
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.lineHeight = lineHeight
        }

        /// Create context for a page's content area
        public init(page: PDF.Page) {
            self.x = page.margins.left
            self.y = page.margins.top
            self.initialX = page.margins.left
            self.initialY = page.margins.top
            self.maxY = page.margins.top + page.contentHeight
            self.availableWidth = page.contentWidth
            self.availableHeight = page.contentHeight
            self.font = .helvetica
            self.fontSize = 12
            self.color = .black
            self.lineHeight = 1.2
        }

        /// Line height in points
        public var lineHeightPoints: Double {
            fontSize * lineHeight
        }

        /// Advance Y position by one line
        public mutating func advanceLine() {
            y += lineHeightPoints
        }

        /// Advance Y position by specified amount
        public mutating func advanceY(_ amount: Double) {
            y += amount
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

        // MARK: - Pagination

        /// Check if adding the given height would exceed the page boundary
        public func wouldExceedPage(adding height: Double) -> Bool {
            y + height > maxY
        }

        /// Remaining space on current page
        public var remainingHeight: Double {
            max(0, maxY - y)
        }

        /// Start a new page, saving current operations
        public mutating func startNewPage() {
            // Save current page operations
            if !currentPageOperations.isEmpty {
                completedPages.append(currentPageOperations)
                currentPageOperations = []
            }

            // Reset position to top of page
            y = initialY
            x = initialX
        }

        /// Add operation to current page
        public mutating func addOperation(_ operation: PDF.Operation) {
            currentPageOperations.append(operation)
        }

        /// Add multiple operations to current page
        public mutating func addOperations(_ operations: [PDF.Operation]) {
            currentPageOperations.append(contentsOf: operations)
        }

        /// Get all pages' operations (completed + current)
        public func getAllPages() -> [[PDF.Operation]] {
            var allPages = completedPages
            if !currentPageOperations.isEmpty {
                allPages.append(currentPageOperations)
            }
            return allPages
        }

        /// Check if we need a page break and start new page if so
        ///
        /// Call this before rendering content that requires `height` space.
        /// Returns true if a new page was started.
        @discardableResult
        public mutating func checkPageBreak(needing height: Double) -> Bool {
            if wouldExceedPage(adding: height) {
                startNewPage()
                return true
            }
            return false
        }
    }
}
