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

public import PDF_Standard
import ISO_32000_Flate

extension PDF.Document {
    /// Create a document with builder syntax.
    ///
    /// Full pipeline: `View ──render──▶ Context ──pages──▶ [Page] ──▶ Document`
    ///
    /// Example:
    /// ```swift
    /// let doc = PDF.Document {
    ///     PDF.VStack {
    ///         PDF.Text("Hello, World!")
    ///     }
    /// }
    /// ```
    public init<View: PDF.View>(
        version: ISO_32000.Version = .v1_7,
        info: ISO_32000.Document.Info? = nil,
        mediaBox: ISO_32000.UserSpace.Rectangle = .a4,
        edgeInsets: PDF.EdgeInsets = PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72),
        @PDF.Builder _ build: () -> View
    ) {
        var context = PDF.Context(mediaBox: mediaBox, margins: edgeInsets)
        let view = build()
        View._render(view, context: &context)

        self.init(version: version, info: info, pages: context.pages)
    }
}
