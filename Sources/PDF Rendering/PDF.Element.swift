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
