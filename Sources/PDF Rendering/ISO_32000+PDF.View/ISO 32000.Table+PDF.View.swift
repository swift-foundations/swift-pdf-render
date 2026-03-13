// ISO 32000 Table+PDF.View.swift
// callAsFunction extensions for ISO 32000-2:2020 table structure types.

import ISO_32000
public import Layout_Primitives
public import PDF_Standard
import Rendering_Primitives

// MARK: - Table (14.8.4.8.3)

extension ISO_32000.Table {
    /// Creates a table element with content.
    ///
    /// Content is automatically wrapped in `Stack(spacing: 0)` for vertical row layout.
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
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
        }
    }
}

// MARK: - TR (14.8.4.8.3)

extension ISO_32000.Table.Row {
    /// Creates a table row element with cells.
    ///
    /// Content is automatically wrapped in `Stack(.horizontal)` for horizontal cell layout.
    ///
    /// ```swift
    /// TR() {
    ///     TH(scope: .column) { ... }
    ///     TD() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(.horizontal, content)
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
    ) -> PDF.Element<Self, PDF.Stack<Rendering.ForEach<Content>>> {
        PDF.Element(tag: self) {
            PDF.Stack(.horizontal) {
                Rendering.ForEach(data, content: content)
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
    /// Content is automatically wrapped in `Stack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// THead() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
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
            PDF.Stack(spacing: 0) {
                ISO_32000.TR()(data, content: content)
            }
        }
    }
}

// MARK: - TBody (14.8.4.8.3)

extension ISO_32000.Table.Body {
    /// Creates a table body group with rows.
    ///
    /// Content is automatically wrapped in `Stack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// TBody() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
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
            PDF.Stack(spacing: 0) {
                Rendering.ForEach(data, content: content)
            }
        }
    }
}

// MARK: - TFoot (14.8.4.8.3)

extension ISO_32000.Table.Footer {
    /// Creates a table footer group with rows.
    ///
    /// Content is automatically wrapped in `Stack(spacing: 0)` for vertical row layout.
    ///
    /// ```swift
    /// TFoot() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
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
            PDF.Stack(spacing: 0) {
                ISO_32000.TR()(data, content: content)
            }
        }
    }
}
