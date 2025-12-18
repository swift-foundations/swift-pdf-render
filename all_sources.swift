// ====================
// Package.swift
// ====================
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-pdf-rendering",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "PDF Rendering", targets: ["PDF Rendering"]),
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-renderable", from: "3.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
        .package(url: "https://github.com/swift-standards/swift-pdf-standard", from: "0.3.0"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.16.1"),
    ],
    targets: [
        .target(
            name: "PDF Rendering",
            dependencies: [
                .product(name: "PDF Standard", package: "swift-pdf-standard"),
                .product(name: "Rendering", package: "swift-renderable"),
            ]
        ),
        .testTarget(
            name: "PDF Rendering Tests",
            dependencies: [
                "PDF Rendering",
                .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "StandardsTestSupport", package: "swift-standards"),
            ]
        ),
    ]
)


// ====================
// Sources/PDF Rendering/ISO_32000+PDF.View/ISO 32000.Table+PDF.View.swift
// ====================
// ISO 32000 Table+PDF.View.swift
// callAsFunction extensions for ISO 32000-2:2020 table structure types.

import ISO_32000
public import PDF_Standard

// MARK: - Table (14.8.4.8.3)

extension ISO_32000.Table {
    /// Creates a table element with content.
    ///
    /// Content is automatically wrapped in `VStack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// Table(summary: "Sales data") {
    ///     TR() {
    ///         TD() { ... }
    ///     }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.VStack<Content>> {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0, content)
        }
    }
}

// MARK: - TR (14.8.4.8.3)

extension ISO_32000.Table.Row {
    /// Creates a table row element with cells.
    ///
    /// Content is automatically wrapped in `HStack` for horizontal cell layout.
    ///
    /// ```swift
    /// TR() {
    ///     TH(scope: .column) { ... }
    ///     TD() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.HStack<Content>> {
        PDF.Element(tag: self) {
            PDF.HStack(content)
        }
    }

    /// Creates a table row element by iterating over data.
    ///
    /// ```swift
    /// PDF.Table.Row(headers) { header in
    ///     PDF.Table.Header.Cell(scope: .column)(...) { ... }
    /// }
    /// ```
    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> PDF.Element<Self, PDF.HStack<PDF.ForEach<Content>>> {
        PDF.Element(tag: self) {
            PDF.HStack {
                PDF.ForEach(data, content: content)
            }
        }
    }
}

// MARK: - TH (14.8.4.8.3)

extension ISO_32000.TH {
    /// Creates a table header cell element with content.
    ///
    /// Combines ISO structure attributes with rendering parameters. Content is
    /// automatically wrapped in `Pair<Rectangle, Content>` with the specified styling.
    ///
    /// ```swift
    /// PDF.Table.Header.Cell(
    ///     scope: .column,
    ///     width: 100,
    ///     height: 24,
    ///     fill: .gray(0.9),
    ///     stroke: .gray(0.3)
    /// ) {
    ///     PDF.Text("Product")
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        width: PDF.UserSpace.Width,
        height: PDF.UserSpace.Height,
        fill: PDF.Color? = nil,
        stroke: PDF.Stroke? = nil,
        @PDF.Builder _ content: () -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            Pair(
                PDF.Rectangle(width: width, height: height, fill: fill, stroke: stroke),
                content()
            )
        }
    }
}

// MARK: - TD (14.8.4.8.3)

extension ISO_32000.TD {
    /// Creates a table data cell element with content.
    ///
    /// Combines ISO structure attributes with rendering parameters. Content is
    /// automatically wrapped in `Pair<Rectangle, Content>` with the specified styling.
    ///
    /// ```swift
    /// PDF.Table.Row.Cell(
    ///     width: 100,
    ///     height: 24,
    ///     stroke: .init(.gray(0.3))
    /// ) {
    ///     PDF.Text("Value")
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        width: PDF.UserSpace.Width,
        height: PDF.UserSpace.Height,
        fill: PDF.Color? = nil,
        stroke: PDF.Stroke? = nil,
        @PDF.Builder _ content: () -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            Pair(
                PDF.Rectangle(width: width, height: height, fill: fill, stroke: stroke),
                content()
            )
        }
    }
}

// MARK: - THead (14.8.4.8.3)

extension ISO_32000.Table.Header {
    /// Creates a table header group with rows.
    ///
    /// Content is automatically wrapped in `VStack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// THead() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.VStack<Content>> {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0, content)
        }
    }

    /// Creates a table header group with a single row by iterating over data.
    ///
    /// Wraps the iterated content in TR and THead automatically.
    ///
    /// ```swift
    /// PDF.THead(headers) { header in
    ///     PDF.Table.Header.Cell(scope: .column)(...) { ... }
    /// }
    /// ```
    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0) {
                ISO_32000.TR()(data, content: content)
            }
        }
    }
}

// MARK: - TBody (14.8.4.8.3)

extension ISO_32000.Table.Body {
    /// Creates a table body group with rows.
    ///
    /// Content is automatically wrapped in `VStack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// TBody() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.VStack<Content>> {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0, content)
        }
    }

    /// Creates a table body group by iterating over row data.
    ///
    /// Each element creates a row. Wraps content in TR automatically.
    ///
    /// ```swift
    /// PDF.Table.Body(dataRows) { row in
    ///     PDF.Table.Row(row.values) { value in
    ///         PDF.Table.Row.Cell()(...) { ... }
    ///     }
    /// }
    /// ```
    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0) {
                PDF.ForEach(data, content: content)
            }
        }
    }
}

// MARK: - TFoot (14.8.4.8.3)

extension ISO_32000.Table.Footer {
    /// Creates a table footer group with rows.
    ///
    /// Content is automatically wrapped in `VStack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// TFoot() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.VStack<Content>> {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0, content)
        }
    }

    /// Creates a table footer group with a single row by iterating over data.
    ///
    /// Wraps the iterated content in TR and TFoot automatically.
    ///
    /// ```swift
    /// PDF.TFoot(footerValues) { value in
    ///     PDF.Table.Row.Cell()(...) { ... }
    /// }
    /// ```
    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            PDF.VStack(spacing: 0) {
                ISO_32000.TR()(data, content: content)
            }
        }
    }
}


// ====================
// Sources/PDF Rendering/ISO_32000+PDF.View/ISO_32000.Text+PDF.View.swift
// ====================
//
//  PDF.Text+PDF.View.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

import PDF_Standard

extension ISO_32000.Text: PDF.View {

    public var body: Never {
        fatalError("PDF.Text is a leaf view")
    }

    public static func _render(_ text: Self, context: inout PDF.Context) {
        // Get font and size from text state, falling back to context defaults
        let font = text.state.font.flatMap { context.fontRegistry[$0.name] } ?? context.style.font
        let fontSize = text.state.fontSize ?? context.style.fontSize

        if context.isHorizontalLayout {
            _renderHorizontal(text, font: font, fontSize: fontSize, context: &context)
        } else {
            _renderVertical(text, font: font, fontSize: fontSize, context: &context)
        }
    }

    private static func _renderVertical(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {
        // Word wrap the bytes
        let lines = wrapBytes(
            text.content,
            font: font,
            size: fontSize,
            maxWidth: context.layoutBox.width
        )

        for line in lines {
            // Check for page break before each line
            context.checkPageBreak(needing: context.style.line.height)

            // In top-left coordinates, context.layoutBox.lly is the top of the line box.
            // PDF text is positioned at the baseline, so we offset down by the
            // ascender height (distance from baseline to top of tallest glyphs).
            let baselineY: PDF.UserSpace.Y =
                context.layoutBox.lly + font.metrics.ascender(atSize: fontSize)

            // Emit bytes directly to content stream
            context.emitText(
                line,
                at: PDF.UserSpace.Coordinate(x: context.layoutBox.llx, y: baselineY),
                font: font,
                size: fontSize,
                color: context.style.color
            )

            context.advanceLine()
        }
    }

    private static func _renderHorizontal(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {
        // In horizontal layout, render text on a single line without wrapping
        // and advance X by the text width

        // Check for page break
        context.checkPageBreak(needing: context.style.line.height)

        // Calculate text width
        let textWidth = font.winAnsi.width(of: text.content, atSize: fontSize)

        // In top-left coordinates, context.layoutBox.lly is the top of the line box.
        let baselineY = context.layoutBox.lly + font.metrics.ascender(atSize: fontSize)

        // Emit text
        context.emitText(
            text.content,
            at: PDF.UserSpace.Coordinate(x: context.layoutBox.llx, y: baselineY),
            font: font,
            size: fontSize,
            color: context.style.color
        )

        // Advance X by text width and track Y for max height
        context.advanceX(textWidth)
        context.advanceLine()
    }

    /// Wrap bytes to fit within max width
    ///
    /// Uses O(n) algorithm by tracking running line width instead of recalculating.
    private static func wrapBytes(
        _ bytes: [UInt8],
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        maxWidth: PDF.UserSpace.Width
    ) -> [[UInt8]] {
        guard !bytes.isEmpty else { return [[]] }

        // Pre-calculate space width once
        let spaceWidth = font.winAnsi.width(of: [.ascii.space], atSize: size)

        var lines: [[UInt8]] = []
        var currentLine: [UInt8] = []
        var currentLineWidth: PDF.UserSpace.Width = .zero
        var currentWord: [UInt8] = []

        // Reserve capacity to reduce reallocations
        currentLine.reserveCapacity(256)
        currentWord.reserveCapacity(64)

        /// Process a completed word - add to current line or start new line
        func processWord() {
            guard !currentWord.isEmpty else { return }

            let wordWidth = font.winAnsi.width(of: currentWord, atSize: size)

            if currentLine.isEmpty {
                // First word on line
                if wordWidth > maxWidth {
                    // Word too long - put on its own line
                    lines.append(currentWord)
                } else {
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            } else {
                // Check if word fits on current line (O(1) - no line recalculation!)
                let potentialWidth = currentLineWidth + spaceWidth + wordWidth
                if potentialWidth <= maxWidth {
                    currentLine.append(.ascii.space)
                    currentLine.append(contentsOf: currentWord)
                    currentLineWidth = potentialWidth
                } else {
                    // Start new line - add trailing space to preserve word boundary.
                    // This ensures copy-paste from PDF viewers extracts proper spacing
                    // between the last word of this line and first word of next line.
                    currentLine.append(.ascii.space)
                    lines.append(currentLine)
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            }
            currentWord = []
        }

        for byte in bytes {
            if byte == .ascii.space {
                processWord()
            } else {
                currentWord.append(byte)
            }
        }

        // Handle last word
        processWord()

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }
}


// ====================
// Sources/PDF Rendering/PDF.Builder.swift
// ====================
// PDF.Builder.swift
// Uses typed composition primitives from swift-renderable

public import PDF_Standard
public import Rendering

// Re-export Builder from Renderable
public typealias BuilderRaw = Builder

extension PDF {
    /// Result builder for composing PDF views using typed primitives.
    ///
    /// Uses the same `_Tuple`, `_Conditional`, `_Array`, `Empty` primitives
    /// as HTML.Builder for consistent composition patterns.
    public typealias Builder = BuilderRaw
}

// MARK: - Builder extensions for Empty

extension BuilderRaw {
    /// Creates an empty PDF component when no content is provided.
    public static func buildBlock() -> Empty {
        Empty()
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.ListMarker.swift
// ====================
//
//  PDF.Context.ListMarker.swift
//  swift-pdf-rendering
//

public import Geometry
public import PDF_Standard

// MARK: - List Marker

extension PDF.Context {
    /// A list marker that can be either text-based or graphic.
    ///
    /// Text markers (bullet, numbers) use font glyphs.
    /// Graphic markers (circle for Level 2) are drawn using PDF path operators.
    public enum ListMarker: Sendable {
        /// Text-based marker (bullet, number, square)
        case text(bytes: [UInt8], font: PDF.Font)

        /// Stroked circle marker (hollow circle for Level 2)
        case strokedCircle(
            PDF.UserSpace.Circle,
            strokeWidth: PDF.UserSpace.Width
        )

        /// Filled disc marker (solid circle for Level 1)
        case filledCircle(PDF.UserSpace.Circle)

        /// Filled square marker (for Level 3+)
        case filledSquare(PDF.UserSpace.Rectangle)
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.ListType.swift
// ====================
//
//  PDF.Context.ListType.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

// MARK: - List Type

extension PDF.Context {
    /// Type of list being rendered.
    public enum ListType: Sendable {
        case unordered
        case ordered(startNumber: Int)
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.Style.Resolved.swift
// ====================
// PDF.Context.Style.Resolved.swift
// Fully resolved style with concrete values.

import Geometry
public import Layout
public import PDF_Standard

extension PDF.Context.Style {
    /// A style with all properties resolved to concrete values.
    ///
    /// Unlike `Style`, this cannot have nil values and is ready for rendering.
    public struct Resolved: Sendable, Equatable {
        public var font: PDF.Font
        public var fontSize: PDF.UserSpace.Size<1>
        public var color: PDF.Color
        public var lineHeight: Scale<1, Double>
        public var textMarkup: PDF.Annotation.TextMarkup.Kind?
        public var verticalOffset: PDF.UserSpace.Height
        public var textAlign: Horizontal.Alignment

        public init(
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            lineHeight: Scale<1, Double>,
            textMarkup: PDF.Annotation.TextMarkup.Kind? = nil,
            verticalOffset: PDF.UserSpace.Height = 0,
            textAlign: Horizontal.Alignment = .leading
        ) {
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.lineHeight = lineHeight
            self.textMarkup = textMarkup
            self.verticalOffset = verticalOffset
            self.textAlign = textAlign
        }
    }
}

extension PDF.Context.Style.Resolved {
    /// Line box metrics computed from font and line height.
    public var line: Line { Line(style: self) }

    /// Line box metrics for text layout.
    public struct Line: Sendable {
        private let style: PDF.Context.Style.Resolved

        init(style: PDF.Context.Style.Resolved) {
            self.style = style
        }

        /// Total line height in points (fontSize × lineHeight multiplier).
        public var height: PDF.UserSpace.Height {
            style.fontSize.height * style.lineHeight
        }

        /// Half-leading value using CSS half-leading model.
        ///
        /// The leading is the extra space beyond the font's natural content height
        /// (ascender - descender), distributed symmetrically above and below text.
        public var halfLeading: PDF.UserSpace.Height {
            let ascender = style.font.metrics.ascender(atSize: style.fontSize)
            let descender = style.font.metrics.descender(atSize: style.fontSize)
            let contentHeight = ascender - descender
            return .max(.zero, (height - contentHeight) / 2)
        }

        /// Distance from top of line box to baseline.
        ///
        /// This equals: `halfLeading + ascender`
        public var baselineOffset: PDF.UserSpace.Height {
            halfLeading + style.font.metrics.ascender(atSize: style.fontSize)
        }
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.Style.swift
// ====================
// PDF.Context.Style.swift
// Text styling as a product type with monoid structure.

import Geometry
public import Layout
public import PDF_Standard

extension PDF.Context {
    /// Text styling configuration for rendering.
    ///
    /// `Style` is a **product type** representing the styling dimensions of text rendering.
    /// It forms a **monoid** under the `combined(with:)` operation, allowing styles to be
    /// composed and merged in a principled way.
    ///
    /// ## Category-Theoretic Structure
    ///
    /// - **Product**: Style is a product of independent styling dimensions (font × fontSize × color × ...)
    /// - **Monoid**: (Style, combined, .default) where `combined` merges defined values
    /// - **Functor**: Each styling dimension can be independently transformed
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let base = PDF.Context.Style.default
    /// let heading = base
    ///     .with(font: .helveticaBold)
    ///     .with(fontSize: 24)
    ///     .with(color: .init(gray: 0.2))
    /// ```
    public struct Style: Sendable, Equatable {
        /// Font face
        public var font: PDF.Font?

        /// Font size in points
        public var fontSize: PDF.UserSpace.Size<1>?

        /// Text color
        public var color: PDF.Color?

        /// Line height multiplier (e.g., 1.2 for 120% line height)
        public var lineHeight: Scale<1, Double>?

        /// Text decoration (underline, strikethrough)
        public var textMarkup: PDF.Annotation.TextMarkup.Kind?

        /// Vertical offset for subscript/superscript
        public var verticalOffset: PDF.UserSpace.Height?

        /// Horizontal text alignment
        public var textAlign: Horizontal.Alignment?

        // MARK: - Initializers

        /// Create a style with all properties
        public init(
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Size<1>? = nil,
            color: PDF.Color? = nil,
            lineHeight: Scale<1, Double>? = nil,
            textMarkup: PDF.Annotation.TextMarkup.Kind? = nil,
            verticalOffset: PDF.UserSpace.Height? = nil,
            textAlign: Horizontal.Alignment? = nil
        ) {
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.lineHeight = lineHeight
            self.textMarkup = textMarkup
            self.verticalOffset = verticalOffset
            self.textAlign = textAlign
        }
    }
}

// MARK: - Monoid Identity

extension PDF.Context.Style {
    /// The empty style (monoid identity).
    ///
    /// When combined with any style `s`, returns `s` unchanged:
    /// ```
    /// Style.empty.combined(with: s) == s
    /// s.combined(with: .empty) == s
    /// ```
    public static let empty = PDF.Context.Style()

    /// Default style with concrete values for rendering.
    ///
    /// Unlike `empty`, this provides actual defaults for all properties.
    public static let `default` = PDF.Context.Style(
        font: .helvetica,
        fontSize: 12,
        color: .black,
        lineHeight: 1.2,
        textMarkup: nil,
        verticalOffset: 0,
        textAlign: .leading
    )
}

// MARK: - Monoid Operation

extension PDF.Context.Style {
    /// Combine two styles, with `other`'s defined values taking precedence.
    ///
    /// This is the monoid binary operation. It satisfies:
    /// - **Identity**: `empty.combined(with: s) == s` and `s.combined(with: .empty) == s`
    /// - **Associativity**: `(a.combined(with: b)).combined(with: c) == a.combined(with: b.combined(with: c))`
    ///
    /// - Parameter other: The style to overlay on top of this style
    /// - Returns: A new style with `other`'s non-nil values overriding this style's values
    public func combined(with other: PDF.Context.Style) -> PDF.Context.Style {
        PDF.Context.Style(
            font: other.font ?? self.font,
            fontSize: other.fontSize ?? self.fontSize,
            color: other.color ?? self.color,
            lineHeight: other.lineHeight ?? self.lineHeight,
            textMarkup: other.textMarkup ?? self.textMarkup,
            verticalOffset: other.verticalOffset ?? self.verticalOffset,
            textAlign: other.textAlign ?? self.textAlign
        )
    }

    /// Combine an array of styles from left to right.
    ///
    /// Later styles override earlier ones for any defined property.
    ///
    /// - Parameter styles: Styles to combine
    /// - Returns: The combined style
    public static func combined(_ styles: [PDF.Context.Style]) -> PDF.Context.Style {
        styles.reduce(.empty) { $0.combined(with: $1) }
    }

    /// Combine multiple styles from left to right.
    public static func combined(_ styles: PDF.Context.Style...) -> PDF.Context.Style {
        combined(styles)
    }
}

// MARK: - Fluent Modifiers (Endomorphisms)

extension PDF.Context.Style {
    /// Return a new style with the font changed.
    @inlinable
    public func with(font: PDF.Font) -> PDF.Context.Style {
        var copy = self
        copy.font = font
        return copy
    }

    /// Return a new style with the font size changed.
    @inlinable
    public func with(fontSize: PDF.UserSpace.Size<1>) -> PDF.Context.Style {
        var copy = self
        copy.fontSize = fontSize
        return copy
    }

    /// Return a new style with the color changed.
    @inlinable
    public func with(color: PDF.Color) -> PDF.Context.Style {
        var copy = self
        copy.color = color
        return copy
    }

    /// Return a new style with the line height changed.
    @inlinable
    public func with(lineHeight: Scale<1, Double>) -> PDF.Context.Style {
        var copy = self
        copy.lineHeight = lineHeight
        return copy
    }

    /// Return a new style with text markup changed.
    @inlinable
    public func with(textMarkup: PDF.Annotation.TextMarkup.Kind?) -> PDF.Context.Style {
        var copy = self
        copy.textMarkup = textMarkup
        return copy
    }

    /// Return a new style with vertical offset changed.
    @inlinable
    public func with(verticalOffset: PDF.UserSpace.Height) -> PDF.Context.Style {
        var copy = self
        copy.verticalOffset = verticalOffset
        return copy
    }

    /// Return a new style with text alignment changed.
    @inlinable
    public func with(textAlign: Horizontal.Alignment) -> PDF.Context.Style {
        var copy = self
        copy.textAlign = textAlign
        return copy
    }
}

// MARK: - Resolution

extension PDF.Context.Style {
    /// Resolve this style against defaults, producing a fully-specified style.
    ///
    /// - Parameter defaults: The default values to use for any nil properties
    /// - Returns: A resolved style with all properties defined
    public func resolved(
        against defaults: Resolved = .init(
            font: .helvetica,
            fontSize: 12,
            color: .black,
            lineHeight: 1.2,
            textMarkup: nil,
            verticalOffset: 0,
            textAlign: .leading
        )
    ) -> Resolved {
        Resolved(
            font: font ?? defaults.font,
            fontSize: fontSize ?? defaults.fontSize,
            color: color ?? defaults.color,
            lineHeight: lineHeight ?? defaults.lineHeight,
            textMarkup: textMarkup ?? defaults.textMarkup,
            verticalOffset: verticalOffset ?? defaults.verticalOffset,
            textAlign: textAlign ?? defaults.textAlign
        )
    }
}

// MARK: - Conversion from Resolved

extension PDF.Context.Style {
    /// Create a partial style from a resolved style.
    public init(_ resolved: Resolved) {
        self.init(
            font: resolved.font,
            fontSize: resolved.fontSize,
            color: resolved.color,
            lineHeight: resolved.lineHeight,
            textMarkup: resolved.textMarkup,
            verticalOffset: resolved.verticalOffset,
            textAlign: resolved.textAlign
        )
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.TextRun+Rendering.swift
// ====================
// PDF.Context.TextRun+Rendering.swift
// Optimized text renderer with minimal allocations

import INCITS_4_1986
public import PDF_Standard

// MARK: - Text Run Rendering

extension PDF.Context.TextRun {
    /// Render multiple text runs with proper line wrapping.
    ///
    /// This implementation minimizes allocations by:
    /// - Using a shared byte buffer for all words on a line
    /// - Storing compact word descriptors instead of copying bytes
    /// - Reusing buffers across lines
    public static func renderRuns(
        _ runs: [PDF.Context.TextRun],
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

        let maxWidth = context.layoutBox.width
        let preserveWhitespace = context.preserveWhitespace

        // Shared state - reused across lines
        var state = RenderState()
        state.lineBytes.reserveCapacity(512)
        state.words.reserveCapacity(32)
        state.currentWord.reserveCapacity(64)

        var currentLineWidth: PDF.UserSpace.Width = 0
        var lastWasWhitespace = !preserveWhitespace
        var isFirstLine = true
        var currentRunIndex = 0

        // Cache space width
        var cachedSpaceWidth: PDF.UserSpace.Width = 0
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
                    currentLineWidth = 0
                    lastWasWhitespace = !preserveWhitespace

                case .ascii.space:
                    // Flush current word
                    if !state.currentWord.isEmpty {
                        let width = run.font.winAnsi.width(of: state.currentWord, atSize: run.fontSize)

                        if state.words.isEmpty {
                            state.appendWord(width: width, runIndex: currentRunIndex)
                            currentLineWidth = width
                        } else if currentLineWidth + width <= maxWidth {
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
                        if state.words.isEmpty || currentLineWidth + width <= maxWidth {
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
                    if currentLineWidth + tabWidth <= maxWidth {
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
                } else if currentLineWidth + width <= maxWidth {
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
                gapAfter: 0,
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
        runs: [PDF.Context.TextRun],
        context: inout PDF.Context,
        isFirstLine: Bool
    ) {
        guard !state.words.isEmpty else { return }

        let lineHeight = context.style.line.height
        context.checkPageBreak(needing: lineHeight)

        // Handle list marker
        if isFirstLine, let pending = context.pendingListMarker {
            emitListMarker(pending.marker, at: pending.x, context: &context)
            context.pendingListMarker = nil
        }

        let baselineY = context.layoutBox.lly + context.style.line.baselineOffset

        // Calculate total width (words + gaps, excluding trailing gap)
        var totalWidth: PDF.UserSpace.Width = 0
        for i in 0..<state.words.count {
            totalWidth = totalWidth + state.words[i].width
            if i < state.words.count - 1 {
                totalWidth = totalWidth + state.words[i].gapAfter
            }
        }

        // Calculate alignment
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

        var currentX = context.layoutBox.llx + alignmentOffset

        // Emit words with batching for same-style segments
        var segmentBytes: [UInt8] = []
        segmentBytes.reserveCapacity(256)
        var segmentStartX = currentX
        var segmentWidth: PDF.UserSpace.Width = 0
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
                segmentWidth = 0
            }

            // Add word bytes to segment
            let wordBytes = state.lineBytes[word.byteStart..<(word.byteStart + word.byteLength)]
            segmentBytes.append(contentsOf: wordBytes)
            segmentWidth = segmentWidth + word.width
            currentStyle = wordStyle

            currentX = currentX + word.width

            // Handle gap after word
            if word.gapAfter > 0 {
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
                segmentWidth = 0
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
        context.layoutBox.lly = context.layoutBox.lly + lineHeight
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

        init(run: PDF.Context.TextRun, index: Int = 0) {
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
        run: PDF.Context.TextRun,
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
            context.emitRectangle(bgRect, fill: fillColor, stroke: nil)
        }

        // Text
        context.emitText(
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
                context.emitLine(
                    from: PDF.UserSpace.Coordinate(x: x, y: underlineY),
                    to: PDF.UserSpace.Coordinate(x: x + width, y: underlineY),
                    color: run.color,
                    width: lineWidth
                )
            case .strikeOut:
                let xHeight = run.font.metrics.xHeight(atSize: run.fontSize)
                let strikeY = textY - xHeight / 2
                let lineWidth = max((run.fontSize * 0.05).width, PDF.UserSpace.Width(0.5))
                context.emitLine(
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
        _ marker: PDF.Context.ListMarker,
        at markerX: PDF.UserSpace.X,
        context: inout PDF.Context
    ) {
        let markerBaselineY = context.layoutBox.lly + context.style.line.baselineOffset
        let baseFont = context.style.font
        let baseFontSize = context.style.fontSize

        switch marker {
        case .text(let bytes, let font):
            context.emitText(
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
            let centerX = markerX + circle.radius
            context.emitCircle(
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
            context.emitRectangle(rect, fill: context.style.color, stroke: nil)
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
    private static func buildActualText(from runs: [PDF.Context.TextRun]) -> String {
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


// ====================
// Sources/PDF Rendering/PDF.Context.TextRun.swift
// ====================
// PDF.Context.TextRun.swift

import INCITS_4_1986
public import PDF_Standard

extension PDF.Context {
    /// A styled text segment for inline text flow.
    ///
    /// TextRuns accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct TextRun: Sendable {
        /// The text content as WinAnsi-encoded bytes
        public let bytes: [UInt8]

        /// Font for this text segment
        public let font: PDF.Font

        /// Font size in points
        public let fontSize: PDF.UserSpace.Size<1>

        /// Text color
        public let color: PDF.Color

        /// Text decoration (underline, strikethrough, etc.)
        public let textDecoration: PDF.Annotation.TextMarkup.Kind?

        /// Vertical offset for subscript/superscript (positive = up, negative = down)
        public let verticalOffset: PDF.UserSpace.Height

        /// Optional link URL (makes this text a clickable external link)
        public let linkURL: String?

        /// Optional internal link target ID (for #anchor links)
        /// Used to create pending internal links that are resolved after rendering completes.
        public let internalLinkId: String?

        /// Create a text run from a String (encodes to WinAnsi)
        public init(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            backgroundColor: PDF.Color? = nil,
            verticalOffset: PDF.UserSpace.Height = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            // Encode to WinAnsi, preserving control characters for tokenizer.
            // Control chars (newline, tab, etc.) are handled specially by the tokenizer
            // and must remain as their raw byte values, not be converted to '?'.
            self.bytes = [UInt8](winAnsi: text, withFallback: true, preservingControlChars: true)
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create a text run from pre-encoded bytes
        public init(
            bytes: [UInt8],
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Height = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            self.bytes = bytes
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create text runs from a String, automatically switching to ZapfDingbats for symbols.
        ///
        /// This method scans the text for characters that:
        /// - Can be encoded in WinAnsi → uses the provided font
        /// - Can be encoded in ZapfDingbats but not WinAnsi → switches to ZapfDingbats font
        /// - Cannot be encoded in either → uses the fallback character
        ///
        /// - Parameters:
        ///   - text: The text to convert
        ///   - font: The primary font to use for regular text
        ///   - fontSize: Font size
        ///   - color: Text color
        ///   - textDecoration: Optional text decoration
        ///   - verticalOffset: Vertical offset for sub/superscript
        ///   - linkURL: Optional external link URL
        ///   - internalLinkId: Optional internal link target ID (for #anchor links)
        /// - Returns: Array of TextRuns, possibly with different fonts
        public static func runsWithSymbolSupport(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Height = 0,
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) -> [TextRun] {
            var runs: [TextRun] = []
            var currentWinAnsiBytes: [UInt8] = []
            var currentDingbatsBytes: [UInt8] = []

            func flushWinAnsi() {
                guard !currentWinAnsiBytes.isEmpty else { return }
                runs.append(
                    TextRun(
                        bytes: currentWinAnsiBytes,
                        font: font,
                        fontSize: fontSize,
                        color: color,
                        textDecoration: textDecoration,
                        verticalOffset: verticalOffset,
                        linkURL: linkURL,
                        internalLinkId: internalLinkId
                    )
                )
                currentWinAnsiBytes = []
            }

            func flushDingbats() {
                guard !currentDingbatsBytes.isEmpty else { return }
                runs.append(
                    TextRun(
                        bytes: currentDingbatsBytes,
                        font: .zapfDingbats,
                        fontSize: fontSize,
                        color: color,
                        textDecoration: textDecoration,
                        verticalOffset: verticalOffset,
                        linkURL: linkURL,
                        internalLinkId: internalLinkId
                    )
                )
                currentDingbatsBytes = []
            }

            for scalar in text.unicodeScalars {
                let value = scalar.value

                // Preserve control characters (0x00-0x1F) as-is for tokenizer
                // This includes newlines (0x0A), tabs (0x09), etc.
                if value < 0x20 {
                    flushDingbats()
                    currentWinAnsiBytes.append(UInt8(value))
                }
                // Try WinAnsi first (primary encoding)
                else if let byte = ISO_32000.WinAnsiEncoding.encode(scalar) {
                    flushDingbats()
                    currentWinAnsiBytes.append(byte)
                }
                // Try ZapfDingbats for symbols
                else if let byte = ISO_32000.ZapfDingbatsEncoding.encode(scalar) {
                    flushWinAnsi()
                    currentDingbatsBytes.append(byte)
                }
                // Use fallback from the map, or '?' as last resort
                else if let fallback = ISO_32000.unicodeFallbackMap[value] {
                    flushDingbats()
                    currentWinAnsiBytes.append(contentsOf: fallback)
                } else {
                    flushDingbats()
                    currentWinAnsiBytes.append(0x3F)  // '?'
                }
            }

            // Flush remaining bytes
            flushWinAnsi()
            flushDingbats()

            return runs
        }
    }
}


// ====================
// Sources/PDF Rendering/PDF.Context.swift
// ====================
// PDF.Context.swift
// Rendering context decomposed into categorical primitives.

import Geometry
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
        public var layoutBox: PDF.UserSpace.Rectangle

        /// Resolved text style.
        ///
        /// Forms a monoid under combination.
        public var style: Style.Resolved

        /// Graphics state stack for save/restore operations.
        ///
        /// Mirrors ISO 32000's q/Q operators.
        public var graphicsStack: ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState>

        /// Font registry mapping font reference names to Font objects.
        ///
        /// Per ISO 32000-2:2020 Section 9.3, `Text.State.font` stores only a
        /// `Font.Reference` (the resource name like "F1"). The registry provides
        /// lookup from that name to the full `Font` object with metrics.
        ///
        /// This is populated when fonts are set via `style.font`.
        public var fontRegistry: [String: PDF.Font] = [:]

        // MARK: - Inline Text Flow

        /// Accumulated inline text runs.
        ///
        /// Block elements flush this buffer to render accumulated inline content
        /// as a single wrapped unit. Inline elements append without rendering.
        public var inlineRuns: [PDF.Context.TextRun] = []

        // MARK: - List State

        /// Stack of active lists (for nested list support).
        public var listStack: [(type: ListType, currentIndex: Int)] = []

        /// Pending list marker to be rendered with the first line of text.
        /// Stores the marker and X position where it should be rendered.
        public var pendingListMarker: (marker: ListMarker, x: PDF.UserSpace.X)? = nil

        // MARK: - Modes

        /// Preformatted mode - preserves whitespace in `<pre>` blocks.
        public var preserveWhitespace: Bool = false

        /// Stack spacing - applied between elements in a VStack.
        public var stackSpacing: PDF.UserSpace.Height? = nil

        /// Track Y position before last element rendered (for spacing logic).
        internal var lastElementY: PDF.UserSpace.Y? = nil

        /// Measurement mode - when true, operations are not added.
        public var measurementMode: Bool = false

        // MARK: - Horizontal Layout

        /// Horizontal stack spacing - applied between elements in an HStack.
        public var horizontalSpacing: PDF.UserSpace.Width? = nil

        /// Track X position before last element rendered (for horizontal spacing).
        internal var lastElementX: PDF.UserSpace.X? = nil

        /// Starting Y position for current horizontal row (to track max height).
        internal var horizontalRowStartY: PDF.UserSpace.Y? = nil

        /// Maximum Y reached in current horizontal row.
        internal var horizontalRowMaxY: PDF.UserSpace.Y? = nil

        // MARK: - Text State (for batching BT/ET blocks)

        /// Whether we're inside a BT (begin text) block.
        internal var textBlockOpen: Bool = false

        /// Current font set in the open text block.
        internal var currentTextFont: PDF.Font? = nil

        /// Current font size set in the open text block.
        internal var currentTextFontSize: PDF.UserSpace.Size<1>? = nil

        /// Current fill color set in the open text block.
        internal var currentTextColor: PDF.Color? = nil

        /// Current text position (PDF coordinates, for relative positioning).
        internal var currentTextPosition: PDF.UserSpace.Coordinate? = nil

        // MARK: - Pagination

        /// Initial layout box (for page reset).
        private var initialLayoutBox: PDF.UserSpace.Rectangle

        /// Maximum Y position (bottom boundary).
        private var maxY: PDF.UserSpace.Y

        /// The page's media box (defines page geometry).
        public var mediaBox: ISO_32000.UserSpace.Rectangle

        /// Page top Y coordinate for coordinate conversion (top-left to bottom-left).
        /// Computed from mediaBox.
        public var pageTop: PDF.UserSpace.Y {
            mediaBox.ury
        }

        /// Completed pages (fully built).
        public var completedPages: [PDF.Page] = []

        /// Current page's content stream builder.
        public var currentPageBuilder: ISO_32000.ContentStream.Builder = .init()

        /// Annotations for current page.
        public var currentPageAnnotations: [PDF.Annotation] = []

        /// Pending internal links to be resolved after rendering.
        /// These are collected during text rendering and resolved to destinations later.
        public var pendingInternalLinks: [PendingInternalLink] = []

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
        self.layoutBox = layoutBox
        self.mediaBox = mediaBox
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

// MARK: - Position Operations

extension PDF.Context {
    /// Advance Y position by one line.
    public mutating func advanceLine() {
        // swiftlint:disable:next shorthand_operator
        layoutBox.lly = layoutBox.lly + style.line.height
    }

    /// Advance Y position by specified amount.
    public mutating func advance(_ amount: PDF.UserSpace.Height) {
        // swiftlint:disable:next shorthand_operator
        layoutBox.lly = layoutBox.lly + amount
    }

    /// Advance X position by specified amount (for horizontal layout).
    public mutating func advanceX(_ amount: PDF.UserSpace.Width) {
        // swiftlint:disable:next shorthand_operator
        layoutBox.llx = layoutBox.llx + amount
    }

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
    public mutating func append(inline run: PDF.Context.TextRun) {
        inlineRuns.append(run)
    }

    /// Flush accumulated inline runs, rendering them as a wrapped block.
    public mutating func flushInlineRuns() {
        guard !inlineRuns.isEmpty else { return }
        let runs = inlineRuns
        inlineRuns.removeAll(keepingCapacity: true)  // Reuse buffer
        PDF.Context.TextRun.renderRuns(runs, context: &self)
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
    ///
    /// Returns a ListMarker for the current list item.
    ///
    /// For unordered lists (matches WebKit/CSS default markers):
    /// - Level 1: • (disc) - filled circle using text bullet
    /// - Level 2: ○ (circle) - stroked (hollow) circle using PDF graphics
    /// - Level 3+: ■ (square) - filled square using PDF graphics
    ///
    /// For ordered lists:
    /// - Numbers with period (1., 2., etc.) in text font
    public mutating func nextListMarker() -> ListMarker {
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
                    x: 0,
                    y: 0,
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
    /// Start a new page, building the current page and resetting state.
    public mutating func startNewPage() {
        // Close any open text block before finalizing page
        flushText()

        // Build current page
        let currentStream = ISO_32000.ContentStream(
            data: currentPageBuilder.data,
            fontsUsed: currentPageBuilder.fontsUsed
        )
        let page = PDF.Page(
            mediaBox: mediaBox,
            contentStream: currentStream,
            annotations: currentPageAnnotations
        )
        completedPages.append(page)

        // Reset for new page
        currentPageBuilder = .init()
        currentPageAnnotations = []

        // Reset Y position to top of page, but preserve horizontal margins (llx/urx)
        // This maintains list indentation and other horizontal context across page breaks
        layoutBox.lly = initialLayoutBox.lly
    }

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
        layoutBox.lly + height > maxY
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
                fontsUsed: currentPageBuilder.fontsUsed
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

// MARK: - Content Stream Emission

extension PDF.Context {
    /// Emit WinAnsi-encoded bytes at a position.
    ///
    /// Handles coordinate conversion and font/color setup.
    /// Batches multiple text emissions within a single BT/ET block for efficiency.
    public mutating func emitText(
        _ bytes: [UInt8],
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        guard !measurementMode else { return }

        let pdfY = pageTop - (position.y - PDF.UserSpace.Y.zero)
        let pdfPosition = PDF.UserSpace.Coordinate(x: position.x, y: pdfY)

        // Open text block if not already open
        if !textBlockOpen {
            currentPageBuilder.beginText()
            textBlockOpen = true
            currentTextPosition = nil  // Reset position tracking
        }

        // Set color only if changed
        if currentTextColor != color {
            switch color {
            case .gray(let g):
                currentPageBuilder.setFillColorGray(g)
            case .rgb(let r, let g, let b):
                currentPageBuilder.setFillColorRGB(r: r, g: g, b: b)
            case .cmyk(let c, let m, let y, let k):
                currentPageBuilder.setFillColorCMYK(c: c, m: m, y: y, k: k)
            }
            currentTextColor = color
        }

        // Set font only if changed
        if currentTextFont != font || currentTextFontSize != size {
            currentPageBuilder.setFont(font, size: size)
            currentTextFont = font
            currentTextFontSize = size
        }

        // Position text - use relative positioning if we have a previous position
        if let lastPos = currentTextPosition {
            currentPageBuilder.moveText(
                dx: pdfPosition.x - lastPos.x,
                dy: pdfPosition.y - lastPos.y
            )
        } else {
            // First text in block - position from origin
            currentPageBuilder.moveText(
                dx: pdfPosition.x - .zero,
                dy: pdfPosition.y - .zero
            )
        }
        currentTextPosition = pdfPosition

        currentPageBuilder.showText(bytes)
    }

    /// Emit a text string at a position (encodes to WinAnsi).
    ///
    /// Convenience overload that encodes the string to WinAnsi bytes.
    public mutating func emitText(
        _ text: String,
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        emitText(
            [UInt8](winAnsi: text, withFallback: true),
            at: position,
            font: font,
            size: size,
            color: color
        )
    }

    /// Flush any open text block.
    ///
    /// Call this before switching to graphics operations (lines, rectangles)
    /// or before finalizing the page. Text blocks cannot contain graphics operators.
    public mutating func flushText() {
        guard textBlockOpen else { return }
        currentPageBuilder.endText()
        textBlockOpen = false
        currentTextFont = nil
        currentTextFontSize = nil
        currentTextColor = nil
        currentTextPosition = nil
    }

    /// Emit a line.
    public mutating func emitLine(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width
    ) {
        guard !measurementMode else { return }

        // Must close text block before graphics operations
        flushText()

        let pdfFromY = pageTop - (from.y - PDF.UserSpace.Y.zero)
        let pdfToY = pageTop - (to.y - PDF.UserSpace.Y.zero)

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
        stroke: PDF.Stroke?
    ) {
        guard !measurementMode else { return }

        // Must close text block before graphics operations
        flushText()

        // In top-left coords: rect.lly is top, rect.lly + rect.height is bottom
        // In PDF bottom-left coords: pdfLly = pageTop - (bottom position as displacement)
        let pdfLly = pageTop - (rect.lly + rect.height - PDF.UserSpace.Y.zero)

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
            switch stroke.color {
            case .gray(let g):
                currentPageBuilder.setStrokeColorGray(g)
            case .rgb(let r, let g, let b):
                currentPageBuilder.setStrokeColorRGB(r: r, g: g, b: b)
            case .cmyk(let c, let m, let y, let k):
                currentPageBuilder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
            }
            currentPageBuilder.setLineWidth(stroke.width)
        }

        currentPageBuilder.rectangle(x: rect.llx, y: pdfLly, width: rect.width, height: rect.height)

        if fill != nil && stroke != nil {
            currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            currentPageBuilder.fill()
        } else if stroke != nil {
            currentPageBuilder.stroke()
        }
    }

    /// Emit a circle.
    ///
    /// - Parameters:
    ///   - center: Circle center in top-left coordinate system
    ///   - radius: Circle radius (typed length)
    ///   - fill: Fill color (nil for no fill)
    ///   - stroke: Stroke color (nil for no stroke)
    ///   - strokeWidth: Line width for stroke
    public mutating func emitCircle(
        center: PDF.UserSpace.Coordinate,
        radius: PDF.UserSpace.Length,
        fill: PDF.Color?,
        stroke: PDF.Color?,
        strokeWidth: PDF.UserSpace.Width = .init(1)
    ) {
        guard !measurementMode else { return }

        // Must close text block before graphics operations
        flushText()

        // Transform Y coordinate (top-left origin -> PDF bottom-left origin)
        let pdfCenterY = pageTop - (center.y - PDF.UserSpace.Y.zero)
        let pdfCenter = PDF.UserSpace.Point(
            x: center.x,
            y: pdfCenterY
        )
        let circle = PDF.UserSpace.Circle(
            center: pdfCenter,
            radius: radius
        )

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

        currentPageBuilder.circle(circle)

        if fill != nil && stroke != nil {
            currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            currentPageBuilder.fill()
        } else if stroke != nil {
            currentPageBuilder.stroke()
        }
    }
}


// ====================
// Sources/PDF Rendering/PDF.Document.swift
// ====================
// PDF.Document.swift
//
// Categorical decomposition:
//
//   View ──render──▶ Context ──pages──▶ [Page] ──▶ Document
//
// Primitives:
//   - Context.pages: [PDF.Page]   (page extraction)
//   - Document.init(version:info:pages:)    (final assembly)
//
// This file provides the composition as a convenience init.

import ISO_32000_Flate
public import PDF_Standard

extension PDF.Document {
    /// Create a document with configuration and builder syntax.
    ///
    /// Full pipeline: `View ──render──▶ Context ──pages──▶ [Page] ──▶ Document`
    ///
    /// Example:
    /// ```swift
    /// var config = PDF.Configuration()
    /// config.paperSize = .letter
    /// config.defaultFont = .helvetica
    ///
    /// let doc = PDF.Document(configuration: config) {
    ///     PDF.VStack {
    ///         PDF.Text("Hello, World!")
    ///     }
    /// }
    /// ```
    public init<View: PDF.View>(
        configuration: PDF.Configuration = .init(),
        @PDF.Builder _ build: () -> View
    ) {
        let contentWidth = configuration.mediaBox.width - configuration.margins.horizontal
        let contentHeight = configuration.mediaBox.height - configuration.margins.vertical

        var context = PDF.Context(
            x: .zero + configuration.margins.leading,
            y: .zero + configuration.margins.top,
            availableWidth: contentWidth,
            availableHeight: contentHeight,
            mediaBox: configuration.mediaBox,
            font: configuration.defaultFont,
            fontSize: configuration.defaultFontSize,
            color: configuration.defaultColor,
            lineHeight: Scale(configuration.lineHeight)
        )
        let view = build()
        View._render(view, context: &context)

        // Only include viewer if it differs from defaults
        let viewer: ISO_32000.Viewer? =
            configuration.viewer == .init()
            ? nil
            : configuration.viewer

        self.init(
            version: configuration.version,
            info: configuration.info,
            pages: context.pages,
            viewer: viewer
        )
    }

}


// ====================
// Sources/PDF Rendering/PDF.Element.swift
// ====================
// PDF.Element.swift
// Structure-tagged element for PDF rendering.

public import PDF_Standard

extension PDF {
    /// A structure-tagged element for PDF rendering.
    ///
    /// `PDF.Element` wraps content with structure tag information per ISO 32000-2:2020.
    /// The tag identifies the element type (Table, TR, TH, TD, etc.) and the content
    /// is rendered with appropriate structure tree entries for accessibility.
    ///
    /// ## Usage
    ///
    /// Typically used via `callAsFunction` on ISO structure types:
    ///
    /// ```swift
    /// let th = ISO_32000.TH(scope: .column)
    /// th {
    ///     Pair(PDF.Rectangle(fill: .gray(0.9)), PDF.Text("Header"))
    /// }
    /// ```
    ///
    /// ## Structure Tags
    ///
    /// Per ISO 32000-2:2020 Section 14.8, structure tags create the logical
    /// structure tree that enables accessibility features like screen readers.
    /// The `_render` method emits BMC/BDC...EMC marked content sequences.
    public struct Element<Tag, Content: PDF.View> {
        /// The structure tag (e.g., TH, TD, TR, Table)
        public let tag: Tag

        /// The visual content to render
        public let content: Content

        public init(tag: Tag, @PDF.Builder content: () -> Content) {
            self.tag = tag
            self.content = content()
        }
    }
}

extension PDF.Element: Sendable where Tag: Sendable, Content: Sendable {}

extension PDF.Element: PDF.View {
    public var body: some PDF.View {
        content
    }

    /// Renders the content wrapped in marked content operators.
    ///
    /// Per ISO 32000-2:2020 Section 14.6, emits:
    /// - `/Tag BMC` for simple tags (no attributes)
    /// - `/Tag <<properties>> BDC` for tags with attributes (RowSpan, ColSpan, etc.)
    /// - `EMC` after content
    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Get tag name and properties based on Tag type
        let (tagName, properties) = markedContentInfo(for: view.tag)

        // Emit BMC or BDC
        if let properties = properties, !properties.isEmpty {
            context.currentPageBuilder.beginMarkedContent(tag: tagName, properties: properties)
        } else {
            context.currentPageBuilder.beginMarkedContent(tag: tagName)
        }

        // Render content
        Content._render(view.content, context: &context)

        // Emit EMC
        context.currentPageBuilder.endMarkedContent()
    }

    /// Returns the tag name and optional properties dictionary for marked content.
    ///
    /// Uses static type dispatch to determine the structure type and extract
    /// any non-default attributes (RowSpan, ColSpan, Scope, Headers, etc.).
    private static func markedContentInfo(
        for tag: Tag
    ) -> (ISO_32000.COS.Name, ISO_32000.COS.Dictionary?) {
        // Table (14.8.4.8.3)
        if Tag.self == ISO_32000.Table.self {
            let table = unsafeBitCast(tag, to: ISO_32000.Table.self)
            var props: ISO_32000.COS.Dictionary? = nil
            if let summary = table.summary {
                props = [.summary: .string(ISO_32000.COS.StringValue(summary))]
            }
            return (.table, props)
        }

        // TR (14.8.4.8.3)
        if Tag.self == ISO_32000.TR.self {
            return (.tr, nil)
        }

        // TH (14.8.4.8.3)
        if Tag.self == ISO_32000.TH.self {
            let th = unsafeBitCast(tag, to: ISO_32000.TH.self)
            var props: ISO_32000.COS.Dictionary = [:]
            if th.row.span != 1 {
                props[.rowSpan] = .integer(Int64(th.row.span))
            }
            if th.col.span != 1 {
                props[.colSpan] = .integer(Int64(th.col.span))
            }
            if !th.headers.isEmpty {
                props[.headers] = .array(th.headers.map { .string(ISO_32000.COS.StringValue($0)) })
            }
            if let scope = th.scope {
                props[.scope] = .name(scope.name)
            }
            if let short = th.short {
                props[.short] = .string(ISO_32000.COS.StringValue(short))
            }
            return (.th, props.isEmpty ? nil : props)
        }

        // TD (14.8.4.8.3)
        if Tag.self == ISO_32000.TD.self {
            let td = unsafeBitCast(tag, to: ISO_32000.TD.self)
            var props: ISO_32000.COS.Dictionary = [:]
            if td.row.span != 1 {
                props[.rowSpan] = .integer(Int64(td.row.span))
            }
            if td.col.span != 1 {
                props[.colSpan] = .integer(Int64(td.col.span))
            }
            if !td.headers.isEmpty {
                props[.headers] = .array(td.headers.map { .string(ISO_32000.COS.StringValue($0)) })
            }
            return (.td, props.isEmpty ? nil : props)
        }

        // THead (14.8.4.8.3)
        if Tag.self == ISO_32000.THead.self {
            return (.thead, nil)
        }

        // TBody (14.8.4.8.3)
        if Tag.self == ISO_32000.TBody.self {
            return (.tbody, nil)
        }

        // TFoot (14.8.4.8.3)
        if Tag.self == ISO_32000.TFoot.self {
            return (.tfoot, nil)
        }

        // Fallback: use type name as tag (for custom/future structure types)
        let typeName = String(describing: Tag.self)
        // Type names from Swift are valid PDF names (alphanumeric)
        // swiftlint:disable:next force_try
        return (try! ISO_32000.COS.Name(typeName), nil)
    }
}


// ====================
// Sources/PDF Rendering/PDF.ForEach.swift
// ====================
// PDF.ForEach.swift
// ForEach for PDF rendering, using Rendering._Array internally.

public import Rendering

extension PDF {
    /// A component that creates PDF content for each element in a collection.
    ///
    /// `PDF.ForEach` provides a way to generate content by iterating over
    /// a collection and applying a transform to each element.
    ///
    /// Example:
    /// ```swift
    /// let headers = ["Product", "Units", "Revenue"]
    ///
    /// PDF.ForEach(headers) { header in
    ///     PDF.Table.Header.Cell(scope: .column) {
    ///         Pair(
    ///             PDF.Rectangle(width: 100, height: 24, fill: .gray(0.9)),
    ///             PDF.Text(header)
    ///         )
    ///     }
    /// }
    /// ```
    public struct ForEach<Content: PDF.View> {
        /// The array of content generated from the collection.
        public let content: Rendering._Array<Content>

        /// Creates a new component that generates content for each element in a collection.
        ///
        /// - Parameters:
        ///   - data: The collection to iterate over.
        ///   - content: A closure that transforms each element of the collection into content.
        public init<Data: RandomAccessCollection>(
            _ data: Data,
            @PDF.Builder content: (Data.Element) -> Content
        ) {
            self.content = PDF.Builder.buildArray(data.map(content))
        }
    }
}

extension PDF.ForEach: PDF.View {
    /// The body of this component, which is the array of content.
    public var body: Rendering._Array<Content> {
        content
    }
}

extension PDF.ForEach: Sendable where Content: Sendable {}
extension PDF.ForEach: Hashable where Content: Hashable {}
extension PDF.ForEach: Equatable where Content: Equatable {}


// ====================
// Sources/PDF Rendering/PDF.Page.swift
// ====================
//
//  PDF.Page.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 06/12/2025.
//

extension PDF.Page {
    /// Create a page from a content stream, extracting font resources.
    ///
    /// This is the primitive page construction: `(ContentStream, [Annotation]) → Page`
    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        contentStream: ISO_32000.ContentStream,
        annotations: [PDF.Annotation] = []
    ) {
        var fontResources: [ISO_32000.COS.Name: ISO_32000.Font] = [:]
        for font in contentStream.fontsUsed {
            fontResources[font.resourceName] = font
        }

        self.init(
            mediaBox: mediaBox,
            content: contentStream,
            resources: ISO_32000.Resources(fonts: fontResources),
            annotations: annotations
        )
    }
}


// ====================
// Sources/PDF Rendering/PDF.View.swift
// ====================
// PDF.View.swift

public import PDF_Standard

extension PDF {
    /// A protocol for types that can be rendered to PDF content.
    ///
    /// The `PDF.View` protocol is the core abstraction for PDF layout,
    /// allowing Swift types to represent PDF content in a declarative, composable manner.
    /// Each conforming type renders directly into a `PDF.Context` which accumulates
    /// content stream operations.
    ///
    /// ## Rendering Pipeline
    ///
    /// Views render directly to `ISO_32000.ContentStream` via the context:
    /// ```
    /// PDF.View → PDF.Context (contains ContentStream.Builder) → ISO_32000.ContentStream
    /// ```
    ///
    /// Example:
    /// ```swift
    /// struct MyDocument: PDF.View {
    ///     var body: some PDF.View {
    ///         PDF.VStack(spacing: 12) {
    ///             PDF.Text("Hello, World!")
    ///             PDF.Divider()
    ///             PDF.Text("This is a paragraph of text.")
    ///         }
    ///     }
    /// }
    /// ```
    public protocol View {
        associatedtype Content: PDF.View

        /// The body of this view, defining its structure and content.
        @PDF.Builder var body: Content { get }

        /// Render this view into the context.
        ///
        /// The default implementation delegates to the body's render method.
        static func _render(_ view: Self, context: inout PDF.Context)
    }
}

// MARK: - Default Implementation

extension PDF.View where Content: PDF.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render(_ view: Self, context: inout PDF.Context) {
        Content._render(view.body, context: &context)
    }
}

// MARK: - Convenience Methods

extension PDF.View {
    /// Render this view into a context.
    public func render(context: inout PDF.Context) {
        Self._render(self, context: &context)
    }
}


// ====================
// Sources/PDF Rendering/Views/Empty+PDF.View.swift
// ====================
// Empty+PDF.View.swift
// PDF.View conformance for Empty

public import PDF_Standard
public import Rendering

extension Empty: PDF.View {
    public typealias Content = Never

    public static func _render(_ markup: Empty, context: inout PDF.Context) {
        // Produces no output
    }

    public var body: Never { fatalError("Empty uses direct rendering") }
}


// ====================
// Sources/PDF Rendering/Views/Never+PDF.View.swift
// ====================
//
//  File.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

extension Never: PDF.View {
    public typealias Content = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        fatalError("Never cannot be rendered")
    }
}


// ====================
// Sources/PDF Rendering/Views/Optional+PDF.View.swift
// ====================
// Optional+PDF.View.swift
// PDF.View conformance for Optional

public import PDF_Standard

extension Optional: PDF.View where Wrapped: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Optional uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        if let wrapped = view {
            Wrapped._render(wrapped, context: &context)
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/PDF.Divider+PDF.View.swift
// ====================
// PDF.Divider.swift

public import PDF_Standard

extension PDF {
    /// Horizontal divider line
    public struct Divider: PDF.View, Sendable {
        public typealias Content = Never

        /// Line color
        public var color: PDF.Color

        /// Line thickness (stroke width and vertical extent)
        public var thickness: PDF.UserSpace.Size<1>

        /// Vertical padding around the line
        public var padding: PDF.UserSpace.Height

        /// Create a divider
        public init(
            color: PDF.Color = .gray50,
            thickness: PDF.UserSpace.Size<1> = 0.5,
            padding: PDF.UserSpace.Height = 6
        ) {
            self.color = color
            self.thickness = thickness
            self.padding = padding
        }

        public var body: Never {
            fatalError("PDF.Divider is a leaf view")
        }

        public static func _render(_ view: Self, context: inout PDF.Context) {
            // Check for page break before rendering
            context.checkPageBreak(needing: view.padding + view.thickness.height + view.padding)

            context.advance(view.padding)

            let lineY = context.layoutBox.lly
            let startX = context.layoutBox.llx

            context.advance(view.thickness.height + view.padding)

            // Emit line directly to content stream
            context.emitLine(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(
                    x: context.layoutBox.llx + context.layoutBox.width,
                    y: lineY
                ),
                color: view.color,
                width: view.thickness.width
            )
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/PDF.Rectangle+PDF.View.swift
// ====================
// PDF.Rectangle.swift
// A styled rectangle view for PDF rendering

public import PDF_Standard

extension PDF.Rectangle: PDF.View {

    public var body: Never {
        fatalError("PDF.Rectangle is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check for page break before rendering
        context.checkPageBreak(needing: view.rect.height)

        // Emit rectangle at current position + rectangle's offset
        // Use (X - .zero) to convert coordinate to displacement for addition
        let renderRect = PDF.UserSpace.Rectangle(
            x: context.layoutBox.llx + (view.rect.llx - .zero),
            y: context.layoutBox.lly + (view.rect.lly - .zero),
            width: view.rect.width,
            height: view.rect.height
        )

        context.emitRectangle(
            renderRect,
            fill: view.fill,
            stroke: view.stroke
        )

        if context.isHorizontalLayout {
            // In horizontal layout: advance X by width, track Y for max height
            context.advanceX(view.rect.width)
            context.advance(view.rect.height)
        } else {
            // In vertical layout: advance Y by height
            context.advance(view.rect.height)
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/PDF.Spacer+PDF.View.swift
// ====================
// PDF.Spacer.swift

public import PDF_Standard

extension PDF {
    /// Fixed-size spacing element
    public struct Spacer: PDF.View, Sendable {
        public typealias Content = Never

        /// Vertical space (displacement)
        public var height: PDF.UserSpace.Height

        /// Create a spacer
        public init(_ height: PDF.UserSpace.Height) {
            self.height = height
        }

        public var body: Never {
            fatalError("PDF.Spacer is a leaf view")
        }

        public static func _render(_ view: Self, context: inout PDF.Context) {
            context.advance(view.height)
            // Spacer produces no operations, just advances position
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/PDF.Stack+PDF.View.swift
// ====================
// Stack.swift
// Stack layout namespace.

public import PDF_Standard

extension PDF {
    public typealias Stack = Layout.Stack
}

// MARK: - Typealiases

extension PDF {
    /// Vertical stack layout
    public typealias VStack<C: PDF.View> = Layout.Stack<C>.Vertical

    /// Horizontal stack layout
    public typealias HStack<C: PDF.View> = Layout.Stack<C>.Horizontal
}

extension Layout.Stack: PDF.View where StackContent: PDF.View {
    public var body: some PDF.View {
        switch self {
        case .vertical(let vertical):
            vertical
        case .horizontal(let horizontal):
            horizontal
        }
    }
}

extension Layout.Stack.Horizontal: PDF.View where StackContent: PDF.View {
    /// Create a horizontal stack
    public init(
        spacing: PDF.UserSpace.Width = 0,
        @PDF.Builder _ build: () -> StackContent
    ) {
        self.content = build()
        self.spacing = spacing
    }

    public var body: some PDF.View {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Save previous state
        let previousHorizontalSpacing = context.horizontalSpacing
        let previousLastElementX = context.lastElementX
        let previousHorizontalRowStartY = context.horizontalRowStartY
        let previousHorizontalRowMaxY = context.horizontalRowMaxY
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        // Set up horizontal layout mode
        context.horizontalSpacing = view.spacing
        context.lastElementX = nil
        context.horizontalRowStartY = startY
        context.horizontalRowMaxY = startY

        // Render content - _Tuple will handle horizontal positioning
        StackContent._render(view.content, context: &context)

        // After rendering, advance Y to the maximum reached by any child
        let maxY = context.horizontalRowMaxY ?? startY
        context.layoutBox.lly = maxY

        // Reset X to start (children may have advanced it)
        context.layoutBox.llx = startX

        // Restore previous state
        context.horizontalSpacing = previousHorizontalSpacing
        context.lastElementX = previousLastElementX
        context.horizontalRowStartY = previousHorizontalRowStartY
        context.horizontalRowMaxY = previousHorizontalRowMaxY
    }
}

extension Layout.Stack.Vertical: PDF.View where StackContent: PDF.View {

    /// Create a vertical stack
    public init(
        spacing: PDF.UserSpace.Height = 0,
        @PDF.Builder _ build: () -> StackContent
    ) {
        self.content = build()
        self.spacing = spacing
    }

    public var body: some PDF.View {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Save previous spacing state
        let previousSpacing = context.stackSpacing
        let previousLastY = context.lastElementY

        // Set spacing for this stack (always set, even if 0)
        context.stackSpacing = view.spacing > 0 ? view.spacing : nil
        context.lastElementY = nil

        // Render content - spacing is applied by _Tuple between elements
        StackContent._render(view.content, context: &context)

        // Restore previous spacing state
        context.stackSpacing = previousSpacing
        context.lastElementY = previousLastY
    }
}


// ====================
// Sources/PDF Rendering/Views/Pair+PDF.View.swift
// ====================
// Pair+PDF.View.swift
// PDF.View conformance for Pair - renders first as background, second as foreground.

public import Algebra
public import Layout
public import PDF_Standard

// MARK: - Generic Pair Rendering

extension Pair: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Pair uses direct rendering") }

    /// Renders first as background, second as foreground.
    /// When first is PDF.Rectangle, applies padding and vertical centering.
    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Dispatch to specialized path for Rectangle
        if First.self == PDF.Rectangle.self {
            _renderRectangleContent(
                unsafeBitCast(view.first, to: PDF.Rectangle.self),
                content: view.second,
                context: &context
            )
        } else {
            _renderOverlay(view, context: &context)
        }
    }

    /// Generic overlay: renders first, then second at same position.
    private static func _renderOverlay(_ view: Self, context: inout PDF.Context) {
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        First._render(view.first, context: &context)
        let bgEndX = context.layoutBox.llx
        let bgEndY = context.layoutBox.lly

        context.layoutBox.llx = startX
        context.layoutBox.lly = startY

        Second._render(view.second, context: &context)
        let fgEndX = context.layoutBox.llx
        let fgEndY = context.layoutBox.lly

        if context.isHorizontalLayout {
            context.layoutBox.llx = .max(bgEndX, fgEndX)
            context.layoutBox.lly = .max(bgEndY, fgEndY)
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = .max(bgEndY, fgEndY)
        }
    }

    /// Rectangle + content: padding and cap-height centered vertically.
    private static func _renderRectangleContent(
        _ rect: PDF.Rectangle,
        content: Second,
        context: inout PDF.Context
    ) {
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        let rectWidth = rect.rect.width
        let rectHeight = rect.rect.height

        // Render rectangle (background)
        PDF.Rectangle._render(rect, context: &context)

        // Font metrics for exact positioning
        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        // Horizontal padding
        let padding: PDF.UserSpace.Size<1> = 4

        // Vertical centering: baseline positioned so cap height is centered
        // baseline from top = (cellHeight + capHeight) / 2
        // content Y = startY + baseline - ascender
        let baselineFromTop = (rectHeight + capHeight) / 2
        let contentY = startY + baselineFromTop - ascender

        context.layoutBox.llx = startX + padding.width
        context.layoutBox.lly = contentY

        // Render content (foreground)
        Second._render(content, context: &context)

        // Advance by rectangle dimensions
        if context.isHorizontalLayout {
            context.layoutBox.llx = startX + rectWidth
            context.layoutBox.lly = startY + rectHeight
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = startY + rectHeight
        }
    }
}

// MARK: - Rectangle + Content: Static Dispatch with Centering

extension Pair where First == PDF.Rectangle, Second: PDF.View {
    /// Renders rectangle as background with content centered using font metrics.
    ///
    /// Selected via static dispatch when `First == PDF.Rectangle`.
    ///
    /// ## Vertical Centering Math
    ///
    /// Centers cap height within cell:
    /// ```
    /// baseline from top = (cellHeight + capHeight) / 2
    /// content Y = startY + baseline - ascender
    /// ```
    public static func _render(_ view: Self, context: inout PDF.Context) {
        view.render(padding: 4, verticalAlignment: .center, context: &context)
    }

    /// Renders the rectangle as background with content positioned inside.
    ///
    /// Uses mathematically exact positioning based on font metrics.
    ///
    /// - Parameters:
    ///   - padding: Horizontal padding from rectangle edges (default: 4pt)
    ///   - verticalAlignment: Vertical alignment of content (default: .center)
    public func render(
        padding: PDF.UserSpace.Size<1> = 4,
        verticalAlignment: Vertical.Alignment = .center,
        context: inout PDF.Context
    ) {
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        let rectWidth = first.rect.width
        let rectHeight = first.rect.height

        // Render rectangle (background)
        PDF.Rectangle._render(first, context: &context)

        // Font metrics for exact positioning
        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        // Calculate content Y position based on vertical alignment
        let contentY: PDF.UserSpace.Y
        switch verticalAlignment {
        case .top:
            contentY = startY + padding.height + capHeight - ascender
        case .center:
            let baselineFromTop = (rectHeight + capHeight) / 2
            contentY = startY + baselineFromTop - ascender
        case .bottom, .baseline:
            contentY = startY + rectHeight - padding.height - ascender
        }

        context.layoutBox.llx = startX + padding.width
        context.layoutBox.lly = contentY

        // Render content (foreground)
        Second._render(second, context: &context)

        // Advance by rectangle dimensions
        if context.isHorizontalLayout {
            context.layoutBox.llx = startX + rectWidth
            context.layoutBox.lly = startY + rectHeight
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = startY + rectHeight
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/Stack.swift
// ====================
// Stack.swift
// Stack layout types.

public import PDF_Standard

public enum Layout {

    /// Stack layout namespace
    public enum Stack<StackContent> {
        case vertical(Vertical)
        case horizontal(Horizontal)
    }
}

extension Layout.Stack: Sendable where StackContent: Sendable {}
extension Layout.Stack: Equatable where StackContent: Equatable {}
extension Layout.Stack: Hashable where StackContent: Hashable {}
#if Codable
    extension Layout.Stack: Codable where StackContent: Codable {}
#endif

extension Layout.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal {
        /// Spacing between elements (horizontal displacement)
        public var spacing: PDF.UserSpace.Width

        /// Child content
        public var content: StackContent

    }
}

extension Layout.Stack.Horizontal: Sendable where StackContent: Sendable {}
extension Layout.Stack.Horizontal: Equatable where StackContent: Equatable {}
extension Layout.Stack.Horizontal: Hashable where StackContent: Hashable {}
#if Codable
    extension Layout.Stack.Horizontal: Codable where StackContent: Codable {}
#endif

extension Layout.Stack {
    /// Vertical stack layout
    ///
    /// Arranges child views vertically with specified spacing.
    public struct Vertical {
        /// Spacing between elements (vertical displacement)
        public var spacing: PDF.UserSpace.Height

        /// Child content
        public var content: StackContent
    }
}

extension Layout.Stack.Vertical: Sendable where StackContent: Sendable {}
extension Layout.Stack.Vertical: Equatable where StackContent: Equatable {}
extension Layout.Stack.Vertical: Hashable where StackContent: Hashable {}
#if Codable
    extension Layout.Stack.Vertical: Codable where StackContent: Codable {}
#endif


// ====================
// Sources/PDF Rendering/Views/_Array+PDF.View.swift
// ====================
// _Array+PDF.View.swift
// PDF.View conformance for _Array

public import PDF_Standard
public import Rendering

extension _Array: PDF.View where Element: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Array uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check if we're in horizontal layout mode
        if context.isHorizontalLayout {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        for element in view.elements {
            // Apply spacing before this element if there was a previous element
            if let spacing = context.stackSpacing,
            let lastY = context.lastElementY,
            context.layoutBox.lly > lastY {
                context.advance(spacing)
            }

            // Track Y before rendering
            let yBefore = context.layoutBox.lly

            // Render the element
            Element._render(element, context: &context)

            // Update lastElementY if this element advanced Y
            if context.layoutBox.lly > yBefore {
                context.lastElementY = yBefore
            }
        }
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        // Save the row start Y position
        let rowStartY = context.horizontalRowStartY ?? context.layoutBox.lly

        for element in view.elements {
            // Apply horizontal spacing before this element if there was a previous element
            if let spacing = context.horizontalSpacing,
                let lastX = context.lastElementX,
                context.layoutBox.llx > lastX {
                context.advanceX(spacing)
            }

            // Track X before rendering
            let xBefore = context.layoutBox.llx

            // Reset Y to row start before rendering each child
            context.layoutBox.lly = rowStartY

            // Render the element
            Element._render(element, context: &context)

            // Track maximum Y reached by any child
            context.updateHorizontalRowMaxY()

            // Update lastElementX if this element advanced X
            if context.layoutBox.llx > xBefore {
                context.lastElementX = xBefore
            }
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/_Conditional+PDF.View.swift
// ====================
// _Conditional+PDF.View.swift
// PDF.View conformance for _Conditional

public import PDF_Standard
public import Rendering

extension _Conditional: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Conditional uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        switch view {
        case .first(let first):
            First._render(first, context: &context)
        case .second(let second):
            Second._render(second, context: &context)
        }
    }
}


// ====================
// Sources/PDF Rendering/Views/_Tuple+PDF.View.swift
// ====================
// _Tuple+PDF.View.swift
// PDF.View conformance for _Tuple

public import PDF_Standard
public import Rendering

extension _Tuple: PDF.View where repeat each Content: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Tuple uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check if we're in horizontal layout mode
        if context.isHorizontalLayout {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        func render<T: PDF.View>(_ element: T) {
            // Apply spacing before this element if there was a previous element
            if let spacing = context.stackSpacing,
                let lastY = context.lastElementY,
                context.layoutBox.lly > lastY {
                // Only add spacing if Y actually advanced (element rendered something)
                context.advance(spacing)
            }

            // Track Y before rendering
            let yBefore = context.layoutBox.lly

            // Render the element
            T._render(element, context: &context)

            // Update lastElementY if this element advanced Y
            if context.layoutBox.lly > yBefore {
                context.lastElementY = yBefore
            }
        }
        repeat render(each view.content)
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        // Save the row start Y position
        let rowStartY = context.horizontalRowStartY ?? context.layoutBox.lly

        func render<T: PDF.View>(_ element: T) {
            // Apply horizontal spacing before this element if there was a previous element
            if let spacing = context.horizontalSpacing,
                let lastX = context.lastElementX,
                context.layoutBox.llx > lastX {
                context.advanceX(spacing)
            }

            // Track X before rendering
            let xBefore = context.layoutBox.llx

            // Reset Y to row start before rendering each child
            context.layoutBox.lly = rowStartY

            // Render the element
            T._render(element, context: &context)

            // Track maximum Y reached by any child
            context.updateHorizontalRowMaxY()

            // Update lastElementX if this element advanced X (which it should via width)
            if context.layoutBox.llx > xBefore {
                context.lastElementX = xBefore
            }
        }
        repeat render(each view.content)
    }
}


// ====================
// Sources/PDF Rendering/exports.swift
// ====================
// exports.swift

@_exported public import PDF_Standard


