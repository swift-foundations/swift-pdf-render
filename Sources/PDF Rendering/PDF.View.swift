// PDF.View.swift

public import PDF_Standard

extension PDF {
    /// A protocol for types that can be rendered to PDF content operations.
    ///
    /// The `PDF.View` protocol is the core abstraction for PDF layout,
    /// allowing Swift types to represent PDF content in a declarative, composable manner.
    /// Each conforming type produces PDF content operations with computed positions.
    ///
    /// Example:
    /// ```swift
    /// struct MyDocument: PDF.View {
    ///     var body: some PDF.View {
    ///         PDF.VStack(spacing: 12) {
    ///             PDF.Text("Hello, World!", fontSize: 24)
    ///             PDF.Divider()
    ///             PDF.Text("This is a paragraph of text that will wrap automatically.")
    ///         }
    ///     }
    /// }
    /// ```
    public protocol View: Sendable {
        /// The type of content this view produces
        associatedtype Body: PDF.View

        /// The body of this view
        var body: Body { get }

        /// Render this view into PDF content operations
        func render(context: inout PDF.Context) -> PDF.Content
    }
}

extension PDF.View {
    /// Default implementation delegates to body
    public func render(context: inout PDF.Context) -> PDF.Content {
        body.render(context: &context)
    }
}

// MARK: - Never conformance for leaf views

extension Never: PDF.View {
    public var body: Never {
        fatalError("Never has no body")
    }

    public func render(context: inout PDF.Context) -> PDF.Content {
        fatalError("Never cannot be rendered")
    }
}

// MARK: - Content conformance

extension PDF.Content: PDF.View {
    public var body: Never {
        fatalError("PDF.Content is a leaf view")
    }

    public func render(context: inout PDF.Context) -> PDF.Content {
        self
    }
}
