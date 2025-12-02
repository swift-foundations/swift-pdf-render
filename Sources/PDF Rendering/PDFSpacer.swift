// PDFSpacer.swift

public import PDF_Standard

/// Fixed-size spacing element
public struct PDFSpacer: PDFRenderable, Sendable {
    /// Vertical space in points
    public var height: Double

    /// Create a spacer
    public init(_ height: Double) {
        self.height = height
    }

    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        context.advanceY(height)
        return PDF.Content()
    }
}
