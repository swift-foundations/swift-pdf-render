public import Axis_Primitives
import Dimension_Primitives
import Geometry_Primitives
import ISO_32000_Shared
public import Layout_Primitives
public import PDF_Standard

public typealias LayoutRaw = Layout

extension PDF {

    public typealias Layout = LayoutRaw<Double, ISO_32000_Shared.UserSpace>
}

extension PDF {

    public typealias Stack<C> = PDF.Layout.Stack<C>
}

extension LayoutRaw<Double, ISO_32000_Shared.UserSpace>.Stack: PDF.View where Content: PDF.View {
    public var body: some PDF.View {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        if view.axis == .primary {
            _renderHorizontal(view, context: &context)
        } else {
            _renderVertical(view, context: &context)
        }
    }

    private static func _renderHorizontal(_ view: Self, context: inout PDF.Context) {

        let previousSpacing = context.spacing
        let previousRow = context.row
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        context.spacing.horizontal = view.spacing.width
        context.row.lastX = nil
        context.row.startY = startY
        context.row.maxY = startY

        Content._render(view.content, context: &context)

        let maxY = context.row.maxY ?? startY
        context.layout.box.lly = maxY

        context.layout.box.llx = startX

        context.spacing = previousSpacing
        context.row = previousRow
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {

        let previousSpacing = context.spacing.vertical
        let previousLastY = context.lastY

        let height = view.spacing.height
        context.spacing.vertical = height > .init(0) ? height : nil
        context.lastY = nil

        Content._render(view.content, context: &context)

        context.spacing.vertical = previousSpacing
        context.lastY = previousLastY
    }
}

extension LayoutRaw<Double, ISO_32000_Shared.UserSpace>.Stack where Content: PDF.View {

    public init(
        _ axis: Axis<2> = .vertical,
        spacing: PDF.Layout.Spacing = 0,
        @PDF.Builder _ build: () -> Content
    ) {
        self.init(axis: axis, spacing: spacing, alignment: .center, content: build())
    }
}
