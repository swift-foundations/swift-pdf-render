// _Tuple+PDF.View.swift
// PDF.View conformance for _Tuple

public import PDF_Standard
public import Render_Primitives

extension Render._Tuple: PDF.View where repeat each Content: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Tuple uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check if we're in horizontal layout mode
        if context.spacing.isHorizontal {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        func render<T: PDF.View>(_ element: T) {
            // Apply spacing before this element if there was a previous element
            if let spacing = context.spacing.vertical,
                let lastY = context.lastY,
                context.layout.box.lly > lastY
            {
                // Only add spacing if Y actually advanced (element rendered something)
                context.advance(spacing)
            }

            // Track Y before rendering
            let yBefore = context.layout.box.lly

            // Render the element
            T._render(element, context: &context)

            // Update lastY if this element advanced Y
            if context.layout.box.lly > yBefore {
                context.lastY = yBefore
            }
        }
        repeat render(each view.content)
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        // Save the row start Y position
        let rowStartY = context.row.startY ?? context.layout.box.lly

        func render<T: PDF.View>(_ element: T) {
            // Apply horizontal spacing before this element if there was a previous element
            if let spacing = context.spacing.horizontal,
                let lastX = context.row.lastX,
                context.layout.box.llx > lastX
            {
                context.advance.x(spacing)
            }

            // Track X before rendering
            let xBefore = context.layout.box.llx

            // Reset Y to row start before rendering each child
            context.layout.box.lly = rowStartY

            // Render the element
            T._render(element, context: &context)

            // Track maximum Y reached by any child
            context.updateRowMaxY()

            // Update lastX if this element advanced X (which it should via width)
            if context.layout.box.llx > xBefore {
                context.row.lastX = xBefore
            }
        }
        repeat render(each view.content)
    }
}
