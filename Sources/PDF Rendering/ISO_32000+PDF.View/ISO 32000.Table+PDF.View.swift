// ISO 32000 Table+PDF.View.swift
// callAsFunction extensions for ISO 32000-2:2020 table structure types.

public import PDF_Standard
import ISO_32000

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
        stroke: PDF.Color? = nil,
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
    ///     stroke: .gray(0.3)
    /// ) {
    ///     PDF.Text("Value")
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        width: PDF.UserSpace.Width,
        height: PDF.UserSpace.Height,
        fill: PDF.Color? = nil,
        stroke: PDF.Color? = nil,
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
}
