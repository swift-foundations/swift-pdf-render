// PDFRenderable.swift

public import PDF_Standard

/// A type that can be rendered to PDF content operations
///
/// Layout primitives conform to this protocol and produce
/// PDF content operations with computed positions.
public protocol PDFRenderable: Sendable {
    /// Render this element into PDF content operations
    ///
    /// - Parameter context: The rendering context (mutable to track position)
    /// - Returns: The PDF content operations for this element
    func render(context: inout PDF.RenderContext) -> PDF.Content
}

extension PDF.Content: PDFRenderable {
    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        self
    }
}
