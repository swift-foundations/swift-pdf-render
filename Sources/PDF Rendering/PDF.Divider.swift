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
        public var thickness: PDF.UserSpace.Unit

        /// Vertical padding around the line
        public var padding: PDF.UserSpace.Unit

        /// Create a divider
        public init(
            color: PDF.Color = .gray50,
            thickness: PDF.UserSpace.Unit = 0.5,
            padding: PDF.UserSpace.Unit = 6
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
            let totalHeight = PDF.UserSpace.Height(PDF.UserSpace.Unit(view.padding.value + view.thickness.value + view.padding.value))
            context.checkPageBreak(needing: totalHeight)

            context.advanceY(PDF.UserSpace.Y(PDF.UserSpace.Unit(view.padding.value)))

            let lineY = context.y
            let startX = context.x
            let endX = PDF.UserSpace.X(PDF.UserSpace.Unit(context.x.value + context.availableWidth.value))

            context.advanceY(PDF.UserSpace.Y(PDF.UserSpace.Unit(view.thickness.value + view.padding.value)))

            let operation = PDF.Render.Operation.graphics(.line(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
                color: view.color,
                width: PDF.UserSpace.Width(view.thickness)
            ))

            // Add to context for proper pagination
            context.addOperation(operation)
            // Also add to buffer for callers that use it
            buffer.append(operation)
        }
    }
}
