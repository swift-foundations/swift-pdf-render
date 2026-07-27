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
        // Paginate the row as one unit: pre-measure its height and break to a
        // new page once, before rendering, if it does not fit. (Skipped while
        // already measuring — measurement itself handles breaks virtually.)
        if !context.mode.measurement {
            let rowHeight = context.measure { context in
                _renderHorizontal(view, context: &context)
            }
            if context.page.ensure(height: rowHeight) {
                // The row moved to a new page: re-anchor any enclosing row
                // state (e.g. set by PDF.Stack before this tuple rendered).
                context.row.startY = context.layout.box.lly
                context.row.maxY = context.layout.box.lly
            }
        }

        // Anchor the row start Y position
        var rowStartY = context.row.startY ?? context.layout.box.lly
        context.row.startY = rowStartY

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

            // Track page breaks (real and virtual) to re-anchor the row
            let pagesBefore = context.completedPages.count
            let virtualBreaksBefore = context.mode.pageBreaks

            // Reset Y to row start before rendering each child
            context.layout.box.lly = rowStartY

            // Render the element
            T._render(element, context: &context)

            // A page break mid-row (row taller than the remaining page):
            // re-anchor the row at the top of the new page so subsequent
            // cells do not each trigger their own page break.
            if context.completedPages.count > pagesBefore
                || context.mode.pageBreaks > virtualBreaksBefore
            {
                rowStartY = context.layout.initial.lly
                context.row.startY = rowStartY
                context.row.maxY = context.layout.box.lly
            }

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
