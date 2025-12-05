// PDF.Document.swift
//
// Categorical decomposition:
//
//   View ──render──▶ Context ──finalize──▶ Context.Output ──map(Page.init)──▶ [Page] ──▶ Document
//
// Primitives:
//   - Context.finalize() → Context.Output   (extraction morphism)
//   - Page.init(mediaBox:contentStream:annotations:)  (product construction)
//   - Document.init(version:info:pages:)    (final assembly)
//
// This file provides the composition as a convenience init.

public import PDF_Standard
import ISO_32000_Flate

extension PDF.Document {
    /// Create a document with builder syntax.
    ///
    /// Full pipeline: `View ──render──▶ Context ──finalize──▶ Output ──▶ Document`
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

        self.init(
            version: version,
            info: info,
            mediaBox: mediaBox,
            output: context.finalize()
        )
    }
}

extension PDF.Document {
    /// Create a document from context output.
    ///
    /// Composes: `Context.Output ──map(Page.init)──▶ [Page] ──▶ Document`
    public init(
        version: ISO_32000.Version = .v1_7,
        info: ISO_32000.Document.Info? = nil,
        mediaBox: ISO_32000.UserSpace.Rectangle = .a4,
        output: PDF.Context.Output
    ) {
        let pages = zip(output.contentStreams, output.annotations).map { stream, annotations in
            PDF.Page(mediaBox: mediaBox, contentStream: stream, annotations: annotations)
        }
        
        self.init(version: version, info: info, pages: pages)
    }
}
