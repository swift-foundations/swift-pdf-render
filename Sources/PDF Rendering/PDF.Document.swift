// PDF.Document.swift

public import PDF_Standard
import ISO_32000_Flate

extension PDF {
    /// PDF Document - typealias to ISO_32000.Document
    public typealias Document = ISO_32000.Document
}

extension ISO_32000.Document {
    /// Create a document with builder syntax and metadata
    ///
    /// Example:
    /// ```swift
    /// let doc = ISO_32000.Document(title: "Report", author: "Jane") {
    ///     PDF.VStack {
    ///         PDF.Text("Hello, World!")
    ///     }
    /// }
    /// ```
    public init(
        version: ISO_32000.Version = .v1_7,
        info: ISO_32000.Document.Info? = nil,
        mediaBox: ISO_32000.UserSpace.Rectangle = .a4,
        edgeInsets: PDF.EdgeInsets = PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72),
        @PDF.Builder _ build: () -> some PDF.View
    ) {
        var context = PDF.Context(mediaBox: mediaBox, margins: edgeInsets)

        // Render the view into the context
        let view = build()
        type(of: view)._render(view, context: &context)

        self.init(
            version: version,
            info: info,
            pages: .init(
                mediaBox: mediaBox,
                contentStreams: context.getAllPages(),
                annotations: context.getAllAnnotations()
            )
        )
    }
}

extension [PDF.Page] {
    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        contentStreams: [ISO_32000.ContentStream],
        annotations: [[PDF.Annotation]]
    ) {
        var pages: [PDF.Page] = []
        for (i, contentStream) in contentStreams.enumerated() {
            let pageAnnotations = i < annotations.count ? annotations[i] : []

            // Build font resources from content stream
            var fontResources: [ISO_32000.COS.Name: ISO_32000.Font] = [:]
            for font in contentStream.fontsUsed {
                fontResources[font.resourceName] = font
            }

            pages.append(
                PDF.Page(
                    mediaBox: mediaBox,
                    content: contentStream,
                    resources: ISO_32000.Resources(fonts: fontResources),
                    annotations: pageAnnotations
                )
            )
        }
        self = pages
    }
}
