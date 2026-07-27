// PDF.Rectangle.swift
// A styled rectangle view for PDF rendering

public import PDF_Standard

extension PDF.Rectangle: PDF.View {

    public var body: Never {
        fatalError("PDF.Rectangle is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check for page break before rendering
        context.page.ensure(height: view.rect.height)

        // Emit rectangle at current position + rectangle's offset
        // Use (X - .zero) to convert coordinate to displacement for addition
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
            // In horizontal layout: advance X by width, track Y for max height
            context.advance.x(view.rect.width)
            context.advance(view.rect.height)
        } else {
            // In vertical layout: advance Y by height
            context.advance(view.rect.height)
        }
    }
}
