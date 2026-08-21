public import Layout_Primitives
public import PDF_Standard
public import Pair_Primitives

extension Pair: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Pair uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {

        if First.self == PDF.Rectangle.self {
            unsafe _renderRectangleContent(
                unsafeBitCast(view.first, to: PDF.Rectangle.self),
                content: view.second,
                context: &context
            )
        } else {
            _renderOverlay(view, context: &context)
        }
    }

    private static func _renderOverlay(_ view: Self, context: inout PDF.Context) {
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        First._render(view.first, context: &context)
        let bgEndX = context.layout.box.llx
        let bgEndY = context.layout.box.lly

        context.layout.box.llx = startX
        context.layout.box.lly = startY

        Second._render(view.second, context: &context)
        let fgEndX = context.layout.box.llx
        let fgEndY = context.layout.box.lly

        if context.spacing.isHorizontal {
            context.layout.box.llx = .max(bgEndX, fgEndX)
            context.layout.box.lly = .max(bgEndY, fgEndY)
        } else {
            context.layout.box.llx = startX
            context.layout.box.lly = .max(bgEndY, fgEndY)
        }
    }

    private static func _renderRectangleContent(
        _ rect: PDF.Rectangle,
        content: Second,
        context: inout PDF.Context
    ) {
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        let rectWidth = rect.rect.width
        let rectHeight = rect.rect.height

        PDF.Rectangle._render(rect, context: &context)

        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        let padding: PDF.UserSpace.Size<1> = 4

        let baselineFromTop = (rectHeight + capHeight) / 2
        let contentY = startY + baselineFromTop - ascender

        context.layout.box.llx = startX + padding.width
        context.layout.box.lly = contentY

        Second._render(content, context: &context)

        if context.spacing.isHorizontal {
            context.layout.box.llx = startX + rectWidth
            context.layout.box.lly = startY + rectHeight
        } else {
            context.layout.box.llx = startX
            context.layout.box.lly = startY + rectHeight
        }
    }
}

extension Pair where First == PDF.Rectangle, Second: PDF.View {

    public static func _render(_ view: Self, context: inout PDF.Context) {
        view.render(padding: 4, verticalAlignment: .center, context: &context)
    }

    public func render(
        padding: PDF.UserSpace.Size<1> = 4,
        verticalAlignment: Vertical.Alignment = .center,
        context: inout PDF.Context
    ) {
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        let rectWidth = first.rect.width
        let rectHeight = first.rect.height

        PDF.Rectangle._render(first, context: &context)

        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        let contentY: PDF.UserSpace.Y
        switch verticalAlignment {
        case .top:
            contentY = startY + padding.height + capHeight - ascender

        case .center:
            let baselineFromTop = (rectHeight + capHeight) / 2
            contentY = startY + baselineFromTop - ascender

        case .bottom, .baseline:
            contentY = startY + rectHeight - padding.height - ascender
        }

        context.layout.box.llx = startX + padding.width
        context.layout.box.lly = contentY

        Second._render(second, context: &context)

        if context.spacing.isHorizontal {
            context.layout.box.llx = startX + rectWidth
            context.layout.box.lly = startY + rectHeight
        } else {
            context.layout.box.llx = startX
            context.layout.box.lly = startY + rectHeight
        }
    }
}
