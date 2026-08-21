public import PDF_Standard

extension PDF {

    public struct Element<Tag, Content: PDF.View> {

        public let tag: Tag

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

    public static func _render(_ view: Self, context: inout PDF.Context) {

        let (tagName, properties) = markedContentInfo(for: view.tag)

        if let properties, !properties.isEmpty {
            context.currentPageBuilder.beginMarkedContent(tag: tagName, properties: properties)
        } else {
            context.currentPageBuilder.beginMarkedContent(tag: tagName)
        }

        Content._render(view.content, context: &context)

        context.currentPageBuilder.endMarkedContent()
    }

    private static func markedContentInfo(
        for tag: Tag
    ) -> (ISO_32000.COS.Name, ISO_32000.COS.Dictionary?) {

        if Tag.self == ISO_32000.Table.self {
            let table = unsafe unsafeBitCast(tag, to: ISO_32000.Table.self)
            var props: ISO_32000.COS.Dictionary? = nil
            if let summary = table.summary {
                props = [.summary: .string(ISO_32000.COS.StringValue(summary))]
            }
            return (.table, props)
        }

        if Tag.self == ISO_32000.TR.self {
            return (.tr, nil)
        }

        if Tag.self == ISO_32000.TH.self {
            let th = unsafe unsafeBitCast(tag, to: ISO_32000.TH.self)
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

        if Tag.self == ISO_32000.TD.self {
            let td = unsafe unsafeBitCast(tag, to: ISO_32000.TD.self)
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

        if Tag.self == ISO_32000.THead.self {
            return (.thead, nil)
        }

        if Tag.self == ISO_32000.TBody.self {
            return (.tbody, nil)
        }

        if Tag.self == ISO_32000.TFoot.self {
            return (.tfoot, nil)
        }

        let typeName = String(describing: Tag.self)

        return (try! ISO_32000.COS.Name(typeName), nil)
    }
}
