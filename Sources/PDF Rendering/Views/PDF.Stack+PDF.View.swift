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
        // Render content
        // For typed content, horizontal layout needs custom handling
        StackContent._render(view.content, context: &context)
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
