// PDF.Stack.Vertical.swift
// Vertical stack layout.

public import PDF_Standard
public import Renderable

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

        /// Spacing between elements in points
        public var spacing: PDF.UserSpace.Unit

        /// Create a vertical stack
        public init(spacing: PDF.UserSpace.Unit = 0, @PDF.Builder _ build: () -> C) {
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
                context.stackSpacing = PDF.UserSpace.Y(view.spacing)
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
