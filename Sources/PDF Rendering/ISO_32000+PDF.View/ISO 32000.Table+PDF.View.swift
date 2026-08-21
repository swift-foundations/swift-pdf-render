import ISO_32000
public import Layout_Primitives
public import PDF_Standard

extension ISO_32000.Table {

    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
        }
    }
}

extension ISO_32000.Table.Row {

    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(.horizontal, content)
        }
    }

    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> PDF.Element<Self, PDF.Stack<[Content]>> {
        PDF.Element(tag: self) {
            PDF.Stack(.horizontal) {
                data.map(content)
            }
        }
    }
}

extension ISO_32000.TH {

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

extension ISO_32000.TD {

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

extension ISO_32000.Table.Header {

    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
        }
    }

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

extension ISO_32000.Table.Body {

    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
        }
    }

    public func callAsFunction<Data: RandomAccessCollection, Content: PDF.View>(
        _ data: Data,
        @PDF.Builder content: (Data.Element) -> Content
    ) -> some PDF.View {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0) {
                data.map(content)
            }
        }
    }
}

extension ISO_32000.Table.Footer {

    public func callAsFunction<Content: PDF.View>(
        @PDF.Builder _ content: () -> Content
    ) -> PDF.Element<Self, PDF.Stack<Content>> {
        PDF.Element(tag: self) {
            PDF.Stack(spacing: 0, content)
        }
    }

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
