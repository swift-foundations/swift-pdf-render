// PDF.Document.swift
//
// Categorical decomposition:
//
//   View ──render──▶ Context ──pages──▶ [Page] ──▶ Document
//
// Primitives:
//   - Context.pages: [PDF.Page]   (page extraction)
//   - Document.init(version:info:pages:)    (final assembly)
//
// This file provides the composition as a convenience init.

import ISO_32000_Flate
public import PDF_Standard

extension PDF.Document {
    /// Create a document with configuration and builder syntax.
    ///
    /// Full pipeline: `View ──render──▶ Context ──pages──▶ [Page] ──▶ Document`
    ///
    /// Example:
    /// ```swift
    /// var config = PDF.Configuration()
    /// config.paperSize = .letter
    /// config.defaultFont = .helvetica
    ///
    /// let doc = PDF.Document(configuration: config) {
    ///     PDF.Stack {
    ///         PDF.Text("Hello, World!")
    ///     }
    /// }
    /// ```
    public init<View: PDF.View>(
        configuration: PDF.Configuration = .init(),
        @PDF.Builder _ build: () -> View
    ) {
        var context = PDF.Context(configuration)
        
        let view = build()
        View._render(view, context: &context)

        // Only include viewer if it differs from defaults
        let viewer: ISO_32000.Viewer? =
            configuration.viewer == .init()
            ? nil
            : configuration.viewer

        self.init(
            version: configuration.version,
            info: configuration.info,
            pages: context.pages,
            viewer: viewer
        )
    }
}
