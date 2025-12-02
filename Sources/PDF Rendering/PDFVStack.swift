// PDFVStack.swift

public import PDF_Standard

/// Vertical stack layout
///
/// Arranges child elements vertically with specified spacing.
public struct PDFVStack: PDFRenderable, Sendable {
    /// Child elements
    public var children: [any PDFRenderable]

    /// Spacing between elements
    public var spacing: Double

    /// Create a vertical stack
    public init(spacing: Double = 0, @PDFBuilder _ build: () -> [any PDFRenderable]) {
        self.children = build()
        self.spacing = spacing
    }

    /// Create a vertical stack with explicit children
    public init(spacing: Double = 0, children: [any PDFRenderable]) {
        self.children = children
        self.spacing = spacing
    }

    public func render(context: inout PDF.RenderContext) -> PDF.Content {
        var allOperations: [PDF.Operation] = []

        for (index, child) in children.enumerated() {
            let content = child.render(context: &context)
            allOperations.append(contentsOf: content.operations)

            // Add spacing between elements (not after last)
            if index < children.count - 1 && spacing > 0 {
                context.advanceY(spacing)
            }
        }

        return PDF.Content(operations: allOperations)
    }
}

// MARK: - Result Builder

@resultBuilder
public struct PDFBuilder {
    public static func buildExpression(_ expression: any PDFRenderable) -> [any PDFRenderable] {
        [expression]
    }

    public static func buildBlock(_ components: [any PDFRenderable]...) -> [any PDFRenderable] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [any PDFRenderable]?) -> [any PDFRenderable] {
        component ?? []
    }

    public static func buildEither(first component: [any PDFRenderable]) -> [any PDFRenderable] {
        component
    }

    public static func buildEither(second component: [any PDFRenderable]) -> [any PDFRenderable] {
        component
    }

    public static func buildArray(_ components: [[any PDFRenderable]]) -> [any PDFRenderable] {
        components.flatMap { $0 }
    }
}
