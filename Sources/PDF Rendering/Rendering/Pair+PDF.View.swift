// Pair+PDF.View.swift
// PDF.View conformance for Pair - renders first as background, second as foreground.

public import Algebra_Primitives
public import Layout_Primitives
public import PDF_Standard

// MARK: - Generic Pair Rendering

extension Pair: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Pair uses direct rendering") }

    /// Renders first as background, second as foreground.
    /// When first is PDF.Rectangle, applies padding and vertical centering.
    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Dispatch to specialized path for Rectangle
        if First.self == PDF.Rectangle.self {
            _renderRectangleContent(
                unsafeBitCast(view.first, to: PDF.Rectangle.self),
                content: view.second,
                context: &context
            )
        } else {
            _renderOverlay(view, context: &context)
        }
    }

    /// Generic overlay: renders first, then second at same position.
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

    /// Rectangle + content: padding and cap-height centered vertically.
    private static func _renderRectangleContent(
        _ rect: PDF.Rectangle,
        content: Second,
        context: inout PDF.Context
    ) {
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        let rectWidth = rect.rect.width
        let rectHeight = rect.rect.height

        // Render rectangle (background)
        PDF.Rectangle._render(rect, context: &context)

        // Font metrics for exact positioning
        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        // Horizontal padding
        let padding: PDF.UserSpace.Size<1> = 4

        // Vertical centering: baseline positioned so cap height is centered
        // baseline from top = (cellHeight + capHeight) / 2
        // content Y = startY + baseline - ascender
        let baselineFromTop = (rectHeight + capHeight) / 2
        let contentY = startY + baselineFromTop - ascender

        context.layout.box.llx = startX + padding.width
        context.layout.box.lly = contentY

        // Render content (foreground)
        Second._render(content, context: &context)

        // Advance by rectangle dimensions
        if context.spacing.isHorizontal {
            context.layout.box.llx = startX + rectWidth
            context.layout.box.lly = startY + rectHeight
        } else {
            context.layout.box.llx = startX
            context.layout.box.lly = startY + rectHeight
        }
    }
}

// MARK: - Rectangle + Content: Static Dispatch with Centering

extension Pair where First == PDF.Rectangle, Second: PDF.View {
    /// Renders rectangle as background with content centered using font metrics.
    ///
    /// Selected via static dispatch when `First == PDF.Rectangle`.
    ///
    /// ## Vertical Centering Math
    ///
    /// Centers cap height within cell:
    /// ```
    /// baseline from top = (cellHeight + capHeight) / 2
    /// content Y = startY + baseline - ascender
    /// ```
    public static func _render(_ view: Self, context: inout PDF.Context) {
        view.render(padding: 4, verticalAlignment: .center, context: &context)
    }

    /// Renders the rectangle as background with content positioned inside.
    ///
    /// Uses mathematically exact positioning based on font metrics.
    ///
    /// - Parameters:
    ///   - padding: Horizontal padding from rectangle edges (default: 4pt)
    ///   - verticalAlignment: Vertical alignment of content (default: .center)
    public func render(
        padding: PDF.UserSpace.Size<1> = 4,
        verticalAlignment: Vertical.Alignment = .center,
        context: inout PDF.Context
    ) {
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        let rectWidth = first.rect.width
        let rectHeight = first.rect.height

        // Render rectangle (background)
        PDF.Rectangle._render(first, context: &context)

        // Font metrics for exact positioning
        let font = context.style.font
        let fontSize = context.style.fontSize
        let ascender = font.metrics.ascender(atSize: fontSize)
        let capHeight = font.metrics.capHeight(atSize: fontSize)

        // Calculate content Y position based on vertical alignment
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

        // Render content (foreground)
        Second._render(second, context: &context)

        // Advance by rectangle dimensions
        if context.spacing.isHorizontal {
            context.layout.box.llx = startX + rectWidth
            context.layout.box.lly = startY + rectHeight
        } else {
            context.layout.box.llx = startX
            context.layout.box.lly = startY + rectHeight
        }
    }
}
