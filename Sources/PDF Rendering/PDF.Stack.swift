// PDF.Stack.swift

public import PDF_Standard
public import Renderable

extension PDF {
    /// Stack layout namespace
    public enum Stack {}
}

// MARK: - Vertical Stack

extension PDF.Stack {
    /// Vertical stack layout
    ///
    /// Arranges child views vertically with specified spacing.
    public struct Vertical<C: PDF.View>: PDF.View, Sendable where C: Sendable {
        public typealias Content = C
        public typealias Context = PDF.Context
        public typealias Output = PDF.Render.Operation

        /// Child content
        public var content: C

        /// Spacing between elements
        public var spacing: Double

        /// Create a vertical stack
        public init(spacing: Double = 0, @PDF.Builder _ build: () -> C) {
            self.content = build()
            self.spacing = spacing
        }

        public var body: C {
            content
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context
        ) where Buffer.Element == PDF.Render.Operation {
            // Save previous spacing state
            let previousSpacing = context.stackSpacing
            let previousLastY = context.lastElementY

            // Set spacing for this stack (only if non-zero)
            if view.spacing > 0 {
                context.stackSpacing = PDF.UserSpace.Y(PDF.UserSpace.Unit(view.spacing))
            }
            context.lastElementY = nil

            // Render content - spacing is applied by _Tuple between elements
            C._render(view.content, into: &buffer, context: &context)

            // Restore previous spacing state
            context.stackSpacing = previousSpacing
            context.lastElementY = previousLastY
        }
    }
}

// MARK: - Horizontal Stack

extension PDF.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal<C: PDF.View>: PDF.View, Sendable where C: Sendable {
        public typealias Content = C
        public typealias Context = PDF.Context
        public typealias Output = PDF.Render.Operation

        /// Child content
        public var content: C

        /// Spacing between elements
        public var spacing: Double

        /// Create a horizontal stack
        public init(spacing: Double = 0, @PDF.Builder _ build: () -> C) {
            self.content = build()
            self.spacing = spacing
        }

        public var body: C {
            content
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context
        ) where Buffer.Element == PDF.Render.Operation {
            // Render content
            // For typed content, horizontal layout needs custom handling
            C._render(view.content, into: &buffer, context: &context)
        }
    }
}

// MARK: - Typealiases

extension PDF {
    /// Vertical stack layout
    public typealias VStack<C: PDF.View> = Stack.Vertical<C> where C: Sendable

    /// Horizontal stack layout
    public typealias HStack<C: PDF.View> = Stack.Horizontal<C> where C: Sendable
}
