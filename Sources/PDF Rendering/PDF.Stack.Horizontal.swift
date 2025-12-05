// PDF.Stack.Horizontal.swift
// Horizontal stack layout.

public import PDF_Standard
public import Renderable

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

        /// Spacing between elements in points
        public var spacing: PDF.UserSpace.Unit

        /// Create a horizontal stack
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
            // Render content
            // For typed content, horizontal layout needs custom handling
            C._render(view.content, into: &buffer, context: &context)
        }
    }
}
