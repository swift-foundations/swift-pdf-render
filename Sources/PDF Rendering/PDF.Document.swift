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
    ///     ISO_32000.Page(mediaBox: .a4, operations: [...])
    /// }
    /// ```
    public init(
        version: ISO_32000.Version = .v1_7,
        info: ISO_32000.Document.Info? = nil,
        mediaBox: PDF.Rectangle<ISO_32000.UserSpace.Unit> = .a4,
        edgeInsets: PDF.EdgeInsets = PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72),
        @PDF.Builder _ build: () -> some PDF.View
    ) {

        var context = PDF.Context(mediaBox: mediaBox, margins: edgeInsets)
        
        [PDF.Render.Operation].init(build(), context: &context)
        
        self.init(
            version: version,
            info: info,
            pages: .init(
                mediaBox: mediaBox,
                operations: context.getAllPages(),
                annotations: context.getAllAnnotations()
            )
        )
    }
}

extension [PDF.Page] {
    public init(
        mediaBox: PDF.Rectangle<ISO_32000.UserSpace.Unit>,
        operations: [[PDF.Render.Operation]],
        annotations: [[PDF.Annotation]],
    ){
        var pages: [PDF.Page] = []
        for (i, operations) in operations.enumerated() {
            let annotations = i < annotations.count ? annotations[i] : []
            pages.append(
                PDF.Page(
                    mediaBox: mediaBox,
                    operations: operations,
                    annotations: annotations
                )
            )
        }
        self = pages
    }
}
