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

        public func render(context: inout PDF.Context) -> PDF.Content {
            var allOperations: [PDF.Operation] = []

            for (index, child) in children.enumerated() {
                let content = child.render(context: &context)
                allOperations.append(contentsOf: content.operations)

                if index < children.count - 1 && spacing > 0 {
                    context.advanceY(spacing)
                }
            }

            return PDF.Content(operations: allOperations)
        }
    }
}

// MARK: - Horizontal Stack

extension PDF.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal: PDF.View, Sendable {
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

        public func render(context: inout PDF.Context) -> PDF.Content {
            var allOperations: [PDF.Operation] = []
            let startY = context.y
            var maxHeight: Double = 0

            for (index, child) in children.enumerated() {
                let childStartY = context.y
                let content = child.render(context: &context)
                allOperations.append(contentsOf: content.operations)

                let childHeight = context.y - childStartY
                maxHeight = max(maxHeight, childHeight)

                context.y = startY

                if index < children.count - 1 && spacing > 0 {
                    context.x += spacing
                }
            }

            context.y = startY + maxHeight

            return PDF.Content(operations: allOperations)
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
