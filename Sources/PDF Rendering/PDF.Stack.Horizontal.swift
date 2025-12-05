// PDF.Stack.Horizontal.swift
// Horizontal stack layout.

public import PDF_Standard

extension PDF.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal<C: PDF.View>: PDF.View, Sendable where C: Sendable {
        public typealias Content = C

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

        public static func _render(_ view: Self, context: inout PDF.Context) {
            // Render content
            // For typed content, horizontal layout needs custom handling
            C._render(view.content, context: &context)
        }
    }
}
