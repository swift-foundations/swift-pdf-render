// PDF.RenderContext.swift

public import PDF_Standard

extension PDF {
    /// Rendering context for PDF layout
    ///
    /// Tracks current position, available dimensions, and styling
    /// for layout primitives to use when generating content operations.
    ///
    /// Uses top-left origin with y increasing downward (matching HTML/CSS).
    public struct RenderContext: Sendable {
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
    }
}
