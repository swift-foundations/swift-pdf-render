// PDF.Divider.swift

public import PDF_Standard

extension PDF {
    /// Horizontal divider line
    public struct Divider: PDF.View, Sendable {
        public typealias Content = Never

        /// Line color
        public var color: PDF.Color

        /// Line thickness (stroke width and vertical extent)
        public var thickness: PDF.UserSpace.Size<1>

        /// Vertical padding around the line
        public var padding: PDF.UserSpace.Height

        /// Create a divider
        public init(
            color: PDF.Color = .gray50,
            thickness: PDF.UserSpace.Size<1> = 0.5,
            padding: PDF.UserSpace.Height = .init(6)
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
            context.page.ensure(height: view.padding + view.thickness.height + view.padding)

            context.advance(view.padding)

            let lineY = context.layoutBox.lly
            let startX = context.layoutBox.llx

            context.advance(view.thickness.height + view.padding)

            // Emit line directly to content stream
            context.emit.line(
                from: PDF.UserSpace.Coordinate(x: startX, y: lineY),
                to: PDF.UserSpace.Coordinate(
                    x: context.layoutBox.llx + context.layoutBox.width,
                    y: lineY
                ),
                color: view.color,
                width: view.thickness.width
            )
        }
    }
}
