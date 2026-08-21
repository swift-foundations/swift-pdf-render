public import PDF_Standard

extension PDF {

    public struct Divider: PDF.View, Sendable {

        public var color: PDF.Color

        public var thickness: PDF.UserSpace.Size<1>

        public var padding: PDF.UserSpace.Height

        public init(
            color: PDF.Color = .gray50,
            thickness: PDF.UserSpace.Size<1> = 0.5,
            padding: PDF.UserSpace.Height = .init(6)
        ) {
            self.color = color
            self.thickness = thickness
            self.padding = padding
        }
    }
}

extension PDF.Divider {
    public typealias Content = Never

    public var body: Never {
        fatalError("PDF.Divider is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {

        context.page.ensure(height: view.padding + view.thickness.height + view.padding)

        context.advance(view.padding)

        let lineY = context.layout.box.lly
        let startX = context.layout.box.llx

        context.advance(view.thickness.height + view.padding)

        context.emit.line(
            from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
            to: PDF.UserSpace.Coordinate(
                x: context.layout.box.llx + context.layout.box.width,
                y: lineY
            ),
            color: view.color,
            width: view.thickness.width
        )
    }
}
