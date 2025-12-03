// PDF.Divider.swift

public import PDF_Standard
public import Renderable

extension PDF {
    /// Horizontal divider line
    public struct Divider: PDF.View, Sendable {
        public typealias Content = Never
        public typealias Context = PDF.Context
        public typealias Output = PDF.Render.Operation

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

        public var body: Never {
            fatalError("PDF.Divider is a leaf view")
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context
        ) where Buffer.Element == PDF.Render.Operation {
            // Check for page break before rendering
            let totalHeight = view.padding + view.thickness + view.padding
            context.checkPageBreak(needing: totalHeight)

            context.advanceY(view.padding)

            let lineY = context.y
            let startX = context.x
            let endX = context.x + context.availableWidth

            context.advanceY(view.thickness + view.padding)

            let operation = PDF.Render.Operation.graphics(.line(
                from: PDF.Point(x: startX, y: lineY),
                to: PDF.Point(x: endX, y: lineY),
                color: view.color,
                width: view.thickness
            ))

            // Add to context for proper pagination
            context.addOperation(operation)
            // Also add to buffer for callers that use it
            buffer.append(operation)
        }
    }
}
