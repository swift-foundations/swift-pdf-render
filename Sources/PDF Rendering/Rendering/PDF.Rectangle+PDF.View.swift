public import PDF_Standard

extension PDF.Rectangle: PDF.View {

    public var body: Never {
        fatalError("PDF.Rectangle is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {

        context.page.ensure(height: view.rect.height)

        let renderRect = PDF.UserSpace.Rectangle(
            x: context.layout.box.llx + (view.rect.llx - .zero),
            y: context.layout.box.lly + (view.rect.lly - .zero),
            width: view.rect.width,
            height: view.rect.height
        )

        context.emit.rectangle(
            renderRect,
            fill: view.fill,
            stroke: view.stroke
        )

        if context.spacing.isHorizontal {

            context.advance.x(view.rect.width)
            context.advance(view.rect.height)
        } else {

            context.advance(view.rect.height)
        }
    }
}
