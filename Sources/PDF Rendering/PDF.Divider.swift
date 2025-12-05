// PDF.Divider.swift

public import PDF_Standard

extension PDF {
    /// Horizontal divider line
    public struct Divider: PDF.View, Sendable {
        public typealias Content = Never

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

        public static func _render(_ view: Self, context: inout PDF.Context) {
            // Check for page break before rendering
            let totalHeight = PDF.UserSpace.Height(view.padding + view.thickness + view.padding)
            context.checkPageBreak(needing: totalHeight)

            context.advance(PDF.UserSpace.Y(view.padding))

            let lineY = context.y
            let startX = context.x
            let endX = PDF.UserSpace.X(context.x.value + context.availableWidth.value)

            context.advance(PDF.UserSpace.Y(view.thickness + view.padding))

            // Emit line directly to content stream
            context.emitLine(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(x: endX, y: lineY),
                color: view.color,
                width: PDF.UserSpace.Width(view.thickness)
            )
        }
    }
}
