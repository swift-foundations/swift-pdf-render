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

// MARK: - Stack Typealiases

extension PDF {
    /// Stack layout for arranging PDF views.
    public typealias Stack<C> = PDF.Layout.Stack<C>

    /// Vertical stack layout (items flow top to bottom).
    public typealias VStack<C> = PDF.Layout.Stack<C>

    /// Horizontal stack layout (items flow leading to trailing).
    public typealias HStack<C> = PDF.Layout.Stack<C>
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
        let previousHorizontalSpacing = context.horizontalSpacing
        let previousLastElementX = context.lastElementX
        let previousHorizontalRowStartY = context.horizontalRowStartY
        let previousHorizontalRowMaxY = context.horizontalRowMaxY
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        // Set up horizontal layout mode
        // Project spacing magnitude to width for horizontal axis
        context.horizontalSpacing = view.spacing.width
        context.lastElementX = nil
        context.horizontalRowStartY = startY
        context.horizontalRowMaxY = startY

        // Render content - _Tuple will handle horizontal positioning
        Content._render(view.content, context: &context)

        // After rendering, advance Y to the maximum reached by any child
        let maxY = context.horizontalRowMaxY ?? startY
        context.layoutBox.lly = maxY

        // Reset X to start (children may have advanced it)
        context.layoutBox.llx = startX

        // Restore previous state
        context.horizontalSpacing = previousHorizontalSpacing
        context.lastElementX = previousLastElementX
        context.horizontalRowStartY = previousHorizontalRowStartY
        context.horizontalRowMaxY = previousHorizontalRowMaxY
    }

    private static func _renderVertical(_ view: Self, context: inout PDF.Context) {
        // Save previous spacing state
        let previousSpacing = context.stackSpacing
        let previousLastY = context.lastElementY

        // Set spacing for this stack (always set, even if 0)
        // Project spacing magnitude to height for vertical axis
        let height = view.spacing.height
        context.stackSpacing = height > .init(0) ? height : nil
        context.lastElementY = nil

        // Render content - spacing is applied by _Tuple between elements
        Content._render(view.content, context: &context)

        // Restore previous spacing state
        context.stackSpacing = previousSpacing
        context.lastElementY = previousLastY
    }
}

// MARK: - Convenience Initializers

extension LayoutRaw<Double, ISO_32000_Shared.UserSpace>.Stack where Content: PDF.View {
    /// Creates a vertical stack with the specified spacing.
    public init(
        spacing: PDF.Layout.Spacing = 0,
        @PDF.Builder _ build: () -> Content
    ) {
        self = .vertical(spacing: spacing, content: build())
    }

    /// Creates a vertical stack with the specified spacing.
    public static func vertical(
        spacing: PDF.Layout.Spacing = 0,
        @PDF.Builder _ build: () -> Content
    ) -> Self {
        .vertical(spacing: spacing, content: build())
    }

    /// Creates a horizontal stack with the specified spacing.
    public static func horizontal(
        spacing: PDF.Layout.Spacing = 0,
        @PDF.Builder _ build: () -> Content
    ) -> Self {
        .horizontal(spacing: spacing, content: build())
    }
}
