// PDF.View.swift

public import PDF_Standard

extension PDF {
    /// A protocol for types that can be rendered to PDF content operations.
    ///
    /// The `PDF.View` protocol is the core abstraction for PDF layout,
    /// allowing Swift types to represent PDF content in a declarative, composable manner.
    /// Each conforming type produces PDF content operations with computed positions.
    ///
    /// This protocol mirrors the `Renderable` protocol pattern from swift-renderable,
    /// using static method dispatch for compile-time type safety and monomorphization.
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
        /// The type of content this view's body produces.
        /// For terminal types that implement their own `_render`, use `Never`.
        associatedtype Content: PDF.View

        /// The body of this view, defining its structure and content.
        var body: Content { get }

        /// Renders this view into PDF content operations.
        ///
        /// - Parameters:
        ///   - view: The view to render
        ///   - context: Mutable PDF context tracking position and state
        /// - Returns: PDF content operations for this view
        static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content
    }
}

// MARK: - Default Implementation

extension PDF.View where Content: PDF.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render(
        _ view: Self,
        context: inout PDF.Context
    ) -> PDF.Content {
        Content._render(view.body, context: &context)
    }
}

// MARK: - Never conformance for leaf views

extension Never: PDF.View {
    public typealias Content = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public static func _render(
        _ view: Self,
        context: inout PDF.Context
    ) -> PDF.Content {
        fatalError("Never cannot be rendered")
    }
}

// MARK: - Content conformance (PDF.Content is a leaf type)

extension PDF.Content: PDF.View {
    public typealias Content = Never

    public var body: Never {
        fatalError("PDF.Content is a leaf view")
    }

    public static func _render(
        _ view: Self,
        context: inout PDF.Context
    ) -> PDF.Content {
        view
    }
}

// MARK: - Dynamic dispatch helper

extension PDF {
    /// Renders a view dynamically through existential dispatch.
    /// Use this when you have `any PDF.View` and need to call `_render`.
    @inlinable
    public static func render(
        _ view: some PDF.View,
        context: inout PDF.Context
    ) -> PDF.Content {
        func callRender<V: PDF.View>(_ v: V) -> PDF.Content {
            V._render(v, context: &context)
        }
        return callRender(view)
    }
}
