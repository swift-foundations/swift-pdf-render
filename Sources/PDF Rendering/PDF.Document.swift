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
    ///     PDF.VStack {
    ///         PDF.Text("Hello, World!")
    ///     }
    /// }
    /// ```
    public init<View: PDF.View>(
        configuration: PDF.Configuration = .init(),
        @PDF.Builder _ build: () -> View
    ) {
        let contentWidth = configuration.mediaBox.width - configuration.margins.horizontal
        let contentHeight = configuration.mediaBox.height - configuration.margins.vertical

        var context = PDF.Context(
            x: .zero + configuration.margins.leading,
            y: .zero + configuration.margins.top,
            availableWidth: contentWidth,
            availableHeight: contentHeight,
            mediaBox: configuration.mediaBox,
            font: configuration.defaultFont,
            fontSize: configuration.defaultFontSize,
            color: configuration.defaultColor,
            lineHeight: Scale(configuration.lineHeight)
        )
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
