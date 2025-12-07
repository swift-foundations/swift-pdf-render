// PDF.Context.swift
// Rendering context decomposed into categorical primitives.

public import PDF_Standard
import Geometry

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
        public var layoutBox: PDF.UserSpace.Rectangle
        
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
        private var initialLayoutBox: PDF.UserSpace.Rectangle
        
        /// Maximum Y position (bottom boundary).
        private var maxY: PDF.UserSpace.Y
        
        /// Page height for coordinate conversion (top-left to bottom-left).
        public var pageHeight: PDF.UserSpace.Height
        
        /// Completed pages' content streams.
        public var completedPages: [ISO_32000.ContentStream] = []
        
        /// Current page's content stream builder.
        public var currentPageBuilder: ISO_32000.ContentStream.Builder = .init()
        
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
        layoutBox: PDF.UserSpace.Rectangle,
        pageHeight: PDF.UserSpace.Height,
        style: PDF.Style.Resolved = .init(
            font: .helvetica,
            fontSize: 12,
            color: .black,
            lineHeight: 1.2
        ),
        graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState> = .init(initial: .init())
    ) {
        self.layoutBox = layoutBox
        self.pageHeight = pageHeight
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
        pageHeight: PDF.UserSpace.Height,
        font: PDF.Font = .helvetica,
        fontSize: PDF.UserSpace.Unit = 12,
        color: PDF.Color = .black,
        lineHeight: Scale<1> = 1.2
    ) {
        let box = PDF.UserSpace.Rectangle(
            x: x, y: y,
            width: availableWidth,
            height: availableHeight
        )
        self.init(
            layoutBox: box,
            pageHeight: pageHeight,
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
            availableHeight: contentHeight,
            pageHeight: mediaBox.height
        )
    }
}

// MARK: - Position Operations

extension PDF.Context {
    /// Advance Y position by one line.
    public mutating func advanceLine() {
        layoutBox.lly = PDF.UserSpace.Y(PDF.UserSpace.Unit(layoutBox.lly.value + style.lineHeightPoints.value))
    }
    
    /// Advance Y position by specified amount.
    public mutating func advance(_ amount: PDF.UserSpace.Y) {
        layoutBox.lly = PDF.UserSpace.Y(layoutBox.lly.value + amount.value)
    }
}

// MARK: - Inline Text Flow

extension PDF.Context {
    /// Append a text run to the inline buffer.
    public mutating func append(inline run: PDF.Text.Run) {
        inlineRuns.append(run)
    }
    
    /// Flush accumulated inline runs, rendering them as a wrapped block.
    public mutating func flushInlineRuns() {
        guard !inlineRuns.isEmpty else { return }
        let runs = inlineRuns
        inlineRuns = []
        PDF.Text.Run.renderRuns(runs, context: &self)
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
    /// Start a new page, saving current content stream.
    public mutating func startNewPage() {
        // Finalize current page
        let currentStream = ISO_32000.ContentStream(
            data: currentPageBuilder.data,
            fontsUsed: currentPageBuilder.fontsUsed
        )
        completedPages.append(currentStream)
        completedPageAnnotations.append(currentPageAnnotations)
        
        // Reset for new page
        currentPageBuilder = .init()
        currentPageAnnotations = []
        
        // Reset to initial layout position
        layoutBox.origin = initialLayoutBox.origin
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
        layoutBox.lly.value + height.value > maxY.value
    }
    
    /// Remaining space on current page.
    public var remainingHeight: PDF.UserSpace.Height {
        let remaining = PDF.UserSpace.Height(maxY.value - layoutBox.lly.value)
        return remaining.value > 0 ? remaining : .zero
    }
    
    /// Get all pages' content streams (completed + current).
    public func getAllPages() -> [ISO_32000.ContentStream] {
        var allPages = completedPages
        if !currentPageBuilder.data.isEmpty {
            let currentStream = ISO_32000.ContentStream(
                data: currentPageBuilder.data,
                fontsUsed: currentPageBuilder.fontsUsed
            )
            allPages.append(currentStream)
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
        let startY = layoutBox.lly
        measurementMode = true
        work(&self)
        measurementMode = false
        let height = PDF.UserSpace.Height(layoutBox.lly.value - startY.value)
        layoutBox.lly = startY
        return height
    }
}

// MARK: - Content Stream Emission

extension PDF.Context {
    /// Convert Y coordinate from top-left origin to PDF bottom-left origin.
    @inlinable
    public func convertY(_ y: PDF.UserSpace.Y) -> PDF.UserSpace.Y {
        PDF.UserSpace.Y(pageHeight.value - y.value)
    }
    
    /// Emit a text string at a position.
    ///
    /// Handles coordinate conversion and font/color setup.
    public mutating func emitText(
        _ text: String,
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Unit,
        color: PDF.Color
    ) {
        guard !measurementMode else { return }
        
        let pdfY = convertY(position.y)
        
        currentPageBuilder.beginText()
        
        // Set color
        switch color {
        case .gray(let g):
            currentPageBuilder.setFillColorGray(g)
        case .rgb(let r, let g, let b):
            currentPageBuilder.setFillColorRGB(r: r, g: g, b: b)
        case .cmyk(let c, let m, let y, let k):
            currentPageBuilder.setFillColorCMYK(c: c, m: m, y: y, k: k)
        }
        
        currentPageBuilder.setFont(font, size: size)
        currentPageBuilder.moveText(x: position.x, y: pdfY)
        currentPageBuilder.showText(text)
        currentPageBuilder.endText()
    }
    
    /// Emit a line.
    public mutating func emitLine(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width
    ) {
        guard !measurementMode else { return }
        
        let pdfFromY = convertY(from.y)
        let pdfToY = convertY(to.y)
        
        switch color {
        case .gray(let g):
            currentPageBuilder.setStrokeColorGray(g)
        case .rgb(let r, let g, let b):
            currentPageBuilder.setStrokeColorRGB(r: r, g: g, b: b)
        case .cmyk(let c, let m, let y, let k):
            currentPageBuilder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
        }
        
        currentPageBuilder.setLineWidth(width)
        currentPageBuilder.moveTo(x: from.x, y: pdfFromY)
        currentPageBuilder.lineTo(x: to.x, y: pdfToY)
        currentPageBuilder.stroke()
    }
    
    /// Emit a rectangle.
    public mutating func emitRectangle(
        _ rect: PDF.UserSpace.Rectangle,
        fill: PDF.Color?,
        stroke: PDF.Color?,
        strokeWidth: PDF.UserSpace.Width = .init(1)
    ) {
        guard !measurementMode else { return }
        
        // Transform Y coordinate (rect uses top-left origin, PDF uses bottom-left)
        let pdfY: PDF.UserSpace.Y = .init(pageHeight.value - rect.lly.value - rect.height.value)
        
        if let fill = fill {
            switch fill {
            case .gray(let g):
                currentPageBuilder.setFillColorGray(g)
            case .rgb(let r, let g, let b):
                currentPageBuilder.setFillColorRGB(r: r, g: g, b: b)
            case .cmyk(let c, let m, let y, let k):
                currentPageBuilder.setFillColorCMYK(c: c, m: m, y: y, k: k)
            }
        }
        
        if let stroke = stroke {
            switch stroke {
            case .gray(let g):
                currentPageBuilder.setStrokeColorGray(g)
            case .rgb(let r, let g, let b):
                currentPageBuilder.setStrokeColorRGB(r: r, g: g, b: b)
            case .cmyk(let c, let m, let y, let k):
                currentPageBuilder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
            }
            currentPageBuilder.setLineWidth(strokeWidth)
        }
        
        currentPageBuilder.rectangle(x: rect.llx, y: pdfY, width: rect.width, height: rect.height)
        
        if fill != nil && stroke != nil {
            currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            currentPageBuilder.fill()
        } else if stroke != nil {
            currentPageBuilder.stroke()
        }
    }
}

extension PDF.Context {
    /// Finalize the context, extracting accumulated content.
    ///
    /// Extraction morphism: `Context → Output`
    public func finalize() -> Output {
        Output(
            contentStreams: getAllPages(),
            annotations: getAllAnnotations()
        )
    }
}
