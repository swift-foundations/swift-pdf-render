// _Tuple+PDF.View.swift
// PDF.View conformance for _Tuple

public import PDF_Standard
public import Rendering_Primitives

extension Rendering._Tuple: PDF.View where repeat each Content: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("_Tuple uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check if we're in horizontal layout mode
        if context.isHorizontalLayout {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        func render<T: PDF.View>(_ element: T) {
            // Apply spacing before this element if there was a previous element
            if let spacing = context.stackSpacing,
                let lastY = context.lastElementY,
                context.layoutBox.lly > lastY {
                // Only add spacing if Y actually advanced (element rendered something)
                context.advance(spacing)
            }

            // Track Y before rendering
            let yBefore = context.layoutBox.lly

            // Render the element
            T._render(element, context: &context)

            // Update lastElementY if this element advanced Y
            if context.layoutBox.lly > yBefore {
                context.lastElementY = yBefore
            }
        }
        repeat render(each view.content)
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {
        // Save the row start Y position
        let rowStartY = context.horizontalRowStartY ?? context.layoutBox.lly

        func render<T: PDF.View>(_ element: T) {
            // Apply horizontal spacing before this element if there was a previous element
            if let spacing = context.horizontalSpacing,
                let lastX = context.lastElementX,
                context.layoutBox.llx > lastX {
                context.advanceX(spacing)
            }

            // Track X before rendering
            let xBefore = context.layoutBox.llx

            // Reset Y to row start before rendering each child
            context.layoutBox.lly = rowStartY

            // Render the element
            T._render(element, context: &context)

            // Track maximum Y reached by any child
            context.updateHorizontalRowMaxY()

            // Update lastElementX if this element advanced X (which it should via width)
            if context.layoutBox.llx > xBefore {
                context.lastElementX = xBefore
            }
        }
        repeat render(each view.content)
    }
}
