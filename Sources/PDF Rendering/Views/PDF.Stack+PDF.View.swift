// Stack.swift
// Stack layout namespace.

public import PDF_Standard

extension PDF {
    public typealias Stack = Layout.Stack
}



// MARK: - Typealiases

extension PDF {
    /// Vertical stack layout
    public typealias VStack<C: PDF.View> = Layout.Stack<C>.Vertical

    /// Horizontal stack layout
    public typealias HStack<C: PDF.View> = Layout.Stack<C>.Horizontal
}

extension Layout.Stack: PDF.View where StackContent: PDF.View {
    public var body: some PDF.View {
        switch self {
        case .vertical(let vertical):
            vertical
        case .horizontal(let horizontal):
            horizontal
        }
    }
}

extension Layout.Stack.Horizontal: PDF.View where StackContent: PDF.View {
    /// Create a horizontal stack
    public init(
        spacing: PDF.UserSpace.Unit = 0,
        @PDF.Builder _ build: () -> StackContent
    ) {
        self.content = build()
        self.spacing = spacing
    }

    public var body: some PDF.View {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Save previous state
        let previousHorizontalSpacing = context.horizontalSpacing
        let previousLastElementX = context.lastElementX
        let previousHorizontalRowStartY = context.horizontalRowStartY
        let previousHorizontalRowMaxY = context.horizontalRowMaxY
        let startX = context.layoutBox.llx
        let startY = context.layoutBox.lly

        // Set up horizontal layout mode
        context.horizontalSpacing = PDF.UserSpace.X(view.spacing)
        context.lastElementX = nil
        context.horizontalRowStartY = startY
        context.horizontalRowMaxY = startY

        // Render content - _Tuple will handle horizontal positioning
        StackContent._render(view.content, context: &context)

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
}

extension Layout.Stack.Vertical: PDF.View where StackContent: PDF.View {
    
    /// Create a vertical stack
    public init(
        spacing: PDF.UserSpace.Unit = 0,
        @PDF.Builder _ build: () -> StackContent
    ) {
        self.content = build()
        self.spacing = spacing
    }
    
    public var body: some PDF.View {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Save previous spacing state
        let previousSpacing = context.stackSpacing
        let previousLastY = context.lastElementY

        // Set spacing for this stack (only if non-zero)
        if view.spacing > 0 {
            context.stackSpacing = PDF.UserSpace.Y(view.spacing)
        }
        context.lastElementY = nil

        // Render content - spacing is applied by _Tuple between elements
        StackContent._render(view.content, context: &context)

        // Restore previous spacing state
        context.stackSpacing = previousSpacing
        context.lastElementY = previousLastY
    }
}
