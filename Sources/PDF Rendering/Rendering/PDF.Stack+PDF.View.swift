// PDF.Stack+PDF.View.swift
// Stack layout with PDF.View conformance.

import Dimension_Primitives
import Geometry_Primitives
import ISO_32000_Shared
public import Layout_Primitives
public import PDF_Standard

// MARK: - PDF Layout Namespace

public typealias LayoutRaw = Layout

extension PDF {
    /// Layout namespace specialized for PDF coordinate space.
    public typealias Layout = LayoutRaw<Double, ISO_32000_Shared.UserSpace>
}

// MARK: - Stack Typealias

extension PDF {
    /// Stack layout for arranging PDF views along a horizontal or vertical axis.
    public typealias Stack<C> = PDF.Layout.Stack<C>
}

// MARK: - PDF.View Conformance

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
        // Save previous state
        let previousSpacing = context.spacing
        let previousRow = context.row
        let startX = context.layout.box.llx
        let startY = context.layout.box.lly

        // Set up horizontal layout mode
        // Project spacing magnitude to width for horizontal axis
        context.spacing.horizontal = view.spacing.width
        context.row.lastX = nil
        context.row.startY = startY
        context.row.maxY = startY

        // Render content - _Tuple will handle horizontal positioning
        Content._render(view.content, context: &context)

        // After rendering, advance Y to the maximum reached by any child
        let maxY = context.row.maxY ?? startY
        context.layout.box.lly = maxY

        // Reset X to start (children may have advanced it)
        context.layout.box.llx = startX

        // Restore previous state
        context.spacing = previousSpacing
        context.row = previousRow
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        // Save previous spacing state
        let previousSpacing = context.spacing.vertical
        let previousLastY = context.lastY

        // Set spacing for this stack (always set, even if 0)
        // Project spacing magnitude to height for vertical axis
        let height = view.spacing.height
        context.spacing.vertical = height > .init(0) ? height : nil
        context.lastY = nil

        // Render content - spacing is applied by _Tuple between elements
        Content._render(view.content, context: &context)

        // Restore previous spacing state
        context.spacing.vertical = previousSpacing
        context.lastY = previousLastY
    }
}

// MARK: - Convenience Initializer

extension LayoutRaw<Double, ISO_32000_Shared.UserSpace>.Stack where Content: PDF.View {
    /// Creates a stack along the given axis.
    ///
    /// ```swift
    /// PDF.Stack { }                    // vertical (default)
    /// PDF.Stack(.vertical) { }        // explicit vertical
    /// PDF.Stack(.horizontal) { }      // horizontal
    /// ```
    public init(
        _ axis: Axis<2> = .vertical,
        spacing: PDF.Layout.Spacing = 0,
        @PDF.Builder _ build: () -> Content
    ) {
        self.init(axis: axis, spacing: spacing, alignment: .center, content: build())
    }
}
