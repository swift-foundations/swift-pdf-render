// Array+PDF.View.swift
// PDF.View conformance for Array — enables `for...in` syntax in @PDF.Builder.

public import PDF_Standard

extension Array: PDF.View where Element: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Array uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        if context.isHorizontalLayout {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        for element in view {
            if let spacing = context.stackSpacing,
            let lastY = context.lastElementY,
            context.layoutBox.lly > lastY {
                context.advance(spacing)
            }

            let yBefore = context.layoutBox.lly

            Element._render(element, context: &context)

            if context.layoutBox.lly > yBefore {
                context.lastElementY = yBefore
            }
        }
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        let rowStartY = context.horizontalRowStartY ?? context.layoutBox.lly

        for element in view {
            if let spacing = context.horizontalSpacing,
                let lastX = context.lastElementX,
                context.layoutBox.llx > lastX {
                context.advance.x(spacing)
            }

            let xBefore = context.layoutBox.llx

            context.layoutBox.lly = rowStartY

            Element._render(element, context: &context)

            context.updateHorizontalRowMaxY()

            if context.layoutBox.llx > xBefore {
                context.lastElementX = xBefore
            }
        }
    }
}
