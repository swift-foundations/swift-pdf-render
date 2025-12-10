// ISO 32000 Table+PDF.View.swift
// callAsFunction extensions for ISO 32000-2:2020 table structure types.

public import PDF_Standard
import ISO_32000

// MARK: - Table (14.8.4.8.3)

extension ISO_32000.Table {
    /// Creates a table element with content.
    ///
    /// ```swift
    /// Table(summary: "Sales data") {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - TR (14.8.4.8.3)

extension ISO_32000.`14`.`8`.`4`.`8`.`3`.TR {
    /// Creates a table row element with cells.
    ///
    /// ```swift
    /// TR() {
    ///     TH(scope: .column) { ... }
    ///     TD() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - TH (14.8.4.8.3)

extension ISO_32000.TH {
    /// Creates a table header cell element with content.
    ///
    /// ```swift
    /// TH(scope: .column) {
    ///     Pair(PDF.Rectangle(fill: headerBg), PDF.Text("Product"))
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - TD (14.8.4.8.3)

extension ISO_32000.TD {
    /// Creates a table data cell element with content.
    ///
    /// ```swift
    /// TD() {
    ///     Pair(PDF.Rectangle(), PDF.Text("Value"))
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - THead (14.8.4.8.3)

extension ISO_32000.THead {
    /// Creates a table header group with rows.
    ///
    /// ```swift
    /// THead() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - TBody (14.8.4.8.3)

extension ISO_32000.TBody {
    /// Creates a table body group with rows.
    ///
    /// ```swift
    /// TBody() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}

// MARK: - TFoot (14.8.4.8.3)

extension ISO_32000.TFoot {
    /// Creates a table footer group with rows.
    ///
    /// ```swift
    /// TFoot() {
    ///     TR() { ... }
    /// }
    /// ```
    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, Content> {
        PDF.Element(tag: self, content: content)
    }
}
