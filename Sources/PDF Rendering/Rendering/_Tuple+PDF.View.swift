public import PDF_Standard
public import Render_Primitives

extension Render._Tuple: PDF.View where repeat each Content: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Tuple uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {

        if context.spacing.isHorizontal {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        func render<T: PDF.View>(_ element: T) {

            if let spacing = context.spacing.vertical,
                let lastY = context.lastY,
                context.layout.box.lly > lastY
            {

                context.advance(spacing)
            }

            let yBefore = context.layout.box.lly

            T._render(element, context: &context)

            if context.layout.box.lly > yBefore {
                context.lastY = yBefore
            }
        }
        repeat render(each view.content)
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {

        if !context.mode.measurement {
            let rowHeight = context.measure { context in
                _renderHorizontal(view, context: &context)
            }
            if context.page.ensure(height: rowHeight) {

                context.row.startY = context.layout.box.lly
                context.row.maxY = context.layout.box.lly
            }
        }

        var rowStartY = context.row.startY ?? context.layout.box.lly
        context.row.startY = rowStartY

        func render<T: PDF.View>(_ element: T) {

            if let spacing = context.spacing.horizontal,
                let lastX = context.row.lastX,
                context.layout.box.llx > lastX
            {
                context.advance.x(spacing)
            }

            let xBefore = context.layout.box.llx

            let pagesBefore = context.completedPages.count
            let virtualBreaksBefore = context.mode.pageBreaks

            context.layout.box.lly = rowStartY

            T._render(element, context: &context)

            if context.completedPages.count > pagesBefore
                || context.mode.pageBreaks > virtualBreaksBefore
            {
                rowStartY = context.layout.initial.lly
                context.row.startY = rowStartY
                context.row.maxY = context.layout.box.lly
            }

            context.updateRowMaxY()

            if context.layout.box.llx > xBefore {
                context.row.lastX = xBefore
            }
        }
        repeat render(each view.content)
    }
}
