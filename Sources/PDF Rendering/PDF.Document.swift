// PDF.Document.swift

public import PDF_Standard
import ISO_32000_Flate

extension PDF {
    /// PDF Document - typealias to ISO_32000.Document
    public typealias Document = ISO_32000.Document
}

// MARK: - Convenience Initializers

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
        @PDF.Page.Builder pages build: () -> [ISO_32000.Page]
    ) {
        self.init(
            version: version,
            pages: build(),
            info: info
        )
    }
}

// MARK: - Serialization

extension Array where Element == UInt8 {
    /// Create PDF bytes from a document
    ///
    /// Example:
    /// ```swift
    /// let document = ISO_32000.Document(...)
    /// let bytes = [UInt8](document)
    /// ```
    ///
    /// - Parameters:
    ///   - document: The PDF document to serialize
    ///   - compress: Whether to use FlateDecode compression (default: true)
    public init(
        _ document: ISO_32000.Document,
        compress: Bool = true
    ) {
        var writer = compress
        ? ISO_32000.Writer.flate()
        : ISO_32000.Writer()
        self = writer.write(document)
    }
}
