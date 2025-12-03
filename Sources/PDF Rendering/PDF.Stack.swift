// PDF.Stack.swift

public import PDF_Standard

extension PDF {
    /// Stack layout namespace
    public enum Stack {}
}

// MARK: - Vertical Stack

extension PDF.Stack {
    /// Vertical stack layout
    ///
    /// Arranges child views vertically with specified spacing.
    public struct Vertical: PDF.View, Sendable {
        public typealias Content = Never

        /// Child views
        public var children: [any PDF.View]

        /// Spacing between elements
        public var spacing: Double

        /// Create a vertical stack
        public init(spacing: Double = 0, @PDF.Builder _ build: () -> [any PDF.View]) {
            self.children = build()
            self.spacing = spacing
        }

        /// Create a vertical stack with explicit children
        public init(spacing: Double = 0, children: [any PDF.View]) {
            self.children = children
            self.spacing = spacing
        }

        public var body: Never {
            fatalError("PDF.Stack.Vertical is a leaf view")
        }

        public static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content {
            for (index, child) in view.children.enumerated() {
                _ = PDF.render(child, context: &context)

                if index < view.children.count - 1 && view.spacing > 0 {
                    context.advanceY(view.spacing)
                }
            }

            // Operations are accumulated in context
            return PDF.Content()
        }
    }
}

// MARK: - Horizontal Stack

extension PDF.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal: PDF.View, Sendable {
        public typealias Content = Never

        /// Child views
        public var children: [any PDF.View]

        /// Spacing between elements
        public var spacing: Double

        /// Create a horizontal stack
        public init(spacing: Double = 0, @PDF.Builder _ build: () -> [any PDF.View]) {
            self.children = build()
            self.spacing = spacing
        }

        /// Create a horizontal stack with explicit children
        public init(spacing: Double = 0, children: [any PDF.View]) {
            self.children = children
            self.spacing = spacing
        }

        public var body: Never {
            fatalError("PDF.Stack.Horizontal is a leaf view")
        }

        public static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content {
            let startY = context.y
            var maxHeight: Double = 0

            for (index, child) in view.children.enumerated() {
                let childStartY = context.y
                _ = PDF.render(child, context: &context)

                let childHeight = context.y - childStartY
                maxHeight = max(maxHeight, childHeight)

                context.y = startY

                if index < view.children.count - 1 && view.spacing > 0 {
                    context.x += view.spacing
                }
            }

            context.y = startY + maxHeight

            // Operations are accumulated in context
            return PDF.Content()
        }
    }
}

// MARK: - Typealiases

extension PDF {
    /// Vertical stack layout
    public typealias VStack = Stack.Vertical

    /// Horizontal stack layout
    public typealias HStack = Stack.Horizontal
}
