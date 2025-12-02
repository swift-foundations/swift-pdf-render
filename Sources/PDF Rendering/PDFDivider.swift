// PDFDivider.swift

public import PDF_Standard

/// Horizontal divider line
public struct PDFDivider: PDFRenderable, Sendable {
    /// Line color
    public var color: PDF.Color

    /// Line thickness
    public var thickness: Double

    /// Vertical padding around the line
    public var padding: Double

    /// Create a divider
    public init(
        color: PDF.Color = .gray50,
        thickness: Double = 0.5,
        padding: Double = 6
    ) {
        self.color = color
        self.thickness = thickness
        self.padding = padding
    }

    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        // Add top padding
        context.advanceY(padding)

        // Create line from left to right of available width
        let lineY = context.y
        let startX = context.x
        let endX = context.x + context.availableWidth

        // Advance past line and bottom padding
        context.advanceY(thickness + padding)

        // Return graphics operation for line
        return PDF.Content(operations: [
            .graphics(.line(
                from: PDF.Point(x: startX, y: lineY),
                to: PDF.Point(x: endX, y: lineY),
                color: color,
                width: thickness
            ))
        ])
    }
}
