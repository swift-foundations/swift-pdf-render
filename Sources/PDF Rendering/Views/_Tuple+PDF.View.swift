// _Tuple+PDF.View.swift
// PDF.View conformance for _Tuple

public import Renderable
public import PDF_Standard

extension _Tuple: PDF.View where repeat each Content: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError() }

    public static func _render(_ view: Self, context: inout PDF.Context) {
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
}
