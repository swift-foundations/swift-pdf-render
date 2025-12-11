// Pair+PDF.View.swift
// PDF.View conformance for Pair - renders first as background, second as foreground.

public import PDF_Standard
public import Algebra
public import Layout

// MARK: - Generic Pair Rendering

extension Pair: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError() }

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
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        First._render(view.first, context: &context)
        let bgEndX = context.layoutBox.llx
        let bgEndY = context.layoutBox.lly

        context.layoutBox.llx = startX
        context.layoutBox.lly = startY

        Second._render(view.second, context: &context)
        let fgEndX = context.layoutBox.llx
        let fgEndY = context.layoutBox.lly

        if context.isHorizontalLayout {
            context.layoutBox.llx = PDF.UserSpace.X(max(bgEndX.value, fgEndX.value))
            context.layoutBox.lly = PDF.UserSpace.Y(max(bgEndY.value, fgEndY.value))
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = PDF.UserSpace.Y(max(bgEndY.value, fgEndY.value))
        }
    }

    /// Rectangle + content: padding and cap-height centered vertically.
    private static func _renderRectangleContent(
        _ rect: PDF.Rectangle,
        content: Second,
        context: inout PDF.Context
    ) {
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

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
        let padding: PDF.UserSpace.Unit = 4

        // Vertical centering: baseline positioned so cap height is centered
        // baseline from top = (cellHeight + capHeight) / 2
        // content Y = startY + baseline - ascender
        let baselineFromTop = (rectHeight.value + capHeight.value) / 2.0
        let contentY = startY.value + baselineFromTop - ascender.value

        context.layoutBox.llx = startX + PDF.UserSpace.Width(padding.value)
        context.layoutBox.lly = PDF.UserSpace.Y(contentY)

        // Render content (foreground)
        Second._render(content, context: &context)

        // Advance by rectangle dimensions
        if context.isHorizontalLayout {
            context.layoutBox.llx = startX + rectWidth
            context.layoutBox.lly = startY + rectHeight
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = startY + rectHeight
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
        padding: PDF.UserSpace.Unit = 4,
        verticalAlignment: Vertical.Alignment = .center,
        context: inout PDF.Context
    ) {
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

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
            contentY = PDF.UserSpace.Y(startY.value + padding.value + capHeight.value - ascender.value)
        case .center:
            let baselineFromTop = (rectHeight.value + capHeight.value) / 2.0
            contentY = PDF.UserSpace.Y(startY.value + baselineFromTop - ascender.value)
        case .bottom, .baseline:
            contentY = PDF.UserSpace.Y(startY.value + rectHeight.value - padding.value - ascender.value)
        }

        context.layoutBox.llx = startX + PDF.UserSpace.Width(padding.value)
        context.layoutBox.lly = contentY

        // Render content (foreground)
        Second._render(second, context: &context)

        // Advance by rectangle dimensions
        if context.isHorizontalLayout {
            context.layoutBox.llx = startX + rectWidth
            context.layoutBox.lly = startY + rectHeight
        } else {
            context.layoutBox.llx = startX
            context.layoutBox.lly = startY + rectHeight
        }
    }
}
