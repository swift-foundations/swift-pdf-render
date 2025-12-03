// PDF.View.swift

public import PDF_Standard
public import Renderable

extension PDF {
    /// A protocol for types that can be rendered to PDF content operations.
    ///
    /// The `PDF.View` protocol is the core abstraction for PDF layout,
    /// allowing Swift types to represent PDF content in a declarative, composable manner.
    /// Each conforming type produces PDF content operations with computed positions.
    ///
    /// This protocol extends `Renderable` from swift-renderable with:
    /// - `Output == PDF.Render.Operation` (PDF operations instead of bytes)
    /// - `Context == PDF.Context` (PDF layout state)
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
    public protocol View: Renderable, Sendable
    where Output == PDF.Render.Operation, Context == PDF.Context, Content: PDF.View {
        /// The body of this view, defining its structure and content.
        @PDF.Builder var body: Content { get }
    }
}

// MARK: - Default Implementation

extension PDF.View where Content: PDF.View {
    /// Default implementation delegates to the body's render method.
    @inlinable
    @_disfavoredOverload
    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        Content._render(view.body, into: &buffer, context: &context)
    }
}

// MARK: - Never conformance for leaf views

extension Never: PDF.View {
    public typealias Content = Never
    public typealias Context = PDF.Context
    public typealias Output = PDF.Render.Operation

    public var body: Never {
        fatalError("Never has no body")
    }

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        fatalError("Never cannot be rendered")
    }
}

// Note: PDF.Content (ISO_32000.ContentStream) does NOT conform to PDF.View.
// PDF.Content is the final low-level format (raw bytes), not an intermediate view.
// The rendering pipeline is: PDF.View → [PDF.Render.Operation] → PDF.Page → PDF.Content

// MARK: - Dynamic dispatch helper

extension PDF {
    /// Renders a view dynamically through existential dispatch.
    /// Use this when you have `any PDF.View` and need to call `_render`.
    @inlinable
    public static func render<Buffer: RangeReplaceableCollection>(
        _ view: some PDF.View,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        func callRender<V: PDF.View>(_ v: V) {
            V._render(v, into: &buffer, context: &context)
        }
        callRender(view)
    }
}
