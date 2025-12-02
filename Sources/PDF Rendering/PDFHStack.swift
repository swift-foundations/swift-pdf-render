// PDFHStack.swift

public import PDF_Standard

/// Horizontal stack layout
///
/// Arranges child elements horizontally with specified spacing.
/// Each child renders at the current X position, then X advances.
public struct PDFHStack: PDFRenderable, Sendable {
    /// Child elements
    public var children: [any PDFRenderable]

    /// Spacing between elements
    public var spacing: Double

    /// Create a horizontal stack
    public init(spacing: Double = 0, @PDFBuilder _ build: () -> [any PDFRenderable]) {
        self.children = build()
        self.spacing = spacing
    }

    /// Create a horizontal stack with explicit children
    public init(spacing: Double = 0, children: [any PDFRenderable]) {
        self.children = children
        self.spacing = spacing
    }

    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        var allOperations: [PDF.Operation] = []
        let startY = context.y
        var maxHeight: Double = 0

        for (index, child) in children.enumerated() {
            let childStartY = context.y
            let content = child.render(context: &context)
            allOperations.append(contentsOf: content.operations)

            // Track maximum height used
            let childHeight = context.y - childStartY
            maxHeight = max(maxHeight, childHeight)

            // Reset Y to start position for next horizontal element
            context.y = startY

            // Add spacing between elements (not after last)
            if index < children.count - 1 && spacing > 0 {
                context.x += spacing
            }
        }

        // After all horizontal elements, advance Y by the tallest element
        context.y = startY + maxHeight

        return PDF.Content(operations: allOperations)
    }
}
