// PDF.View.swift

public import PDF_Standard

extension PDF {
    /// A protocol for types that can be rendered to PDF content.
    ///
    /// The `PDF.View` protocol is the core abstraction for PDF layout,
    /// allowing Swift types to represent PDF content in a declarative, composable manner.
    /// Each conforming type renders directly into a `PDF.Context` which accumulates
    /// content stream operations.
    ///
    /// ## Rendering Pipeline
    ///
    /// Views render directly to `ISO_32000.ContentStream` via the context:
    /// ```
    /// PDF.View → PDF.Context (contains ContentStream.Builder) → ISO_32000.ContentStream
    /// ```
    ///
    /// Example:
    /// ```swift
    /// struct MyDocument: PDF.View {
    ///     var body: some PDF.View {
    ///         PDF.VStack(spacing: 12) {
    ///             PDF.Text("Hello, World!")
    ///             PDF.Divider()
    ///             PDF.Text("This is a paragraph of text.")
    ///         }
    ///     }
    /// }
    /// ```
    public protocol View {
        associatedtype Content: PDF.View

        /// The body of this view, defining its structure and content.
        @PDF.Builder var body: Content { get }

        /// Render this view into the context.
        ///
        /// The default implementation delegates to the body's render method.
        static func _render(_ view: Self, context: inout PDF.Context)
    }
}

// MARK: - Default Implementation

extension PDF.View where Content: PDF.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render(_ view: Self, context: inout PDF.Context) {
        Content._render(view.body, context: &context)
    }
}

// MARK: - Convenience Methods

extension PDF.View {
    /// Render this view into a context.
    public func render(context: inout PDF.Context) {
        Self._render(self, context: &context)
    }
}
