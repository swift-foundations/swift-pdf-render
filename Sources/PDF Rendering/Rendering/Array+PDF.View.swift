// Array+PDF.View.swift
// PDF.View conformance for Array — enables `for...in` syntax in @PDF.Builder.

public import PDF_Standard

extension Array: PDF.View where Element: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Array uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        if context.spacing.isHorizontal {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        for element in view {
            if let spacing = context.spacing.vertical,
                let lastY = context.lastY,
                context.layout.box.lly > lastY
            {
                context.advance(spacing)
            }

            let yBefore = context.layout.box.lly

            Element._render(element, context: &context)

            if context.layout.box.lly > yBefore {
                context.lastY = yBefore
            }
        }
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        let rowStartY = context.row.startY ?? context.layout.box.lly

        for element in view {
            if let spacing = context.spacing.horizontal,
                let lastX = context.row.lastX,
                context.layout.box.llx > lastX
            {
                context.advance.x(spacing)
            }

            let xBefore = context.layout.box.llx

            context.layout.box.lly = rowStartY

            Element._render(element, context: &context)

            context.updateRowMaxY()

            if context.layout.box.llx > xBefore {
                context.row.lastX = xBefore
            }
        }
    }
}
