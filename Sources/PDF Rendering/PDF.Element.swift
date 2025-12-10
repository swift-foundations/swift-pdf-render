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
    /// let th = ISO_32000.`14`.`8`.`4`.`8`.`3`.TH(scope: .column)
    /// th {
    ///     Pair(PDF.Rectangle(fill: .gray(0.9)), PDF.Text("Header"))
    /// }
    /// ```
    ///
    /// ## Structure Tags
    ///
    /// Per ISO 32000-2:2020 Section 14.8, structure tags create the logical
    /// structure tree that enables accessibility features like screen readers.
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

    /// Renders the content.
    ///
    /// TODO: In the future, this should emit structure tree entries
    /// via marked content operators (BMC/EMC) per ISO 32000-2:2020 14.6.
    public static func _render(_ view: Self, context: inout PDF.Context) {
        // For now, just render the content
        // Future: emit /Tag BMC ... EMC marked content sequence
        Content._render(view.content, context: &context)
    }
}
