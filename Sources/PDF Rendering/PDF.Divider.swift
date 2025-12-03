// PDF.Divider.swift

public import PDF_Standard

extension PDF {
    /// Horizontal divider line
    public struct Divider: PDF.View, Sendable {
        public typealias Content = Never

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

        public static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content {
            context.advanceY(view.padding)

            let lineY = context.y
            let startX = context.x
            let endX = context.x + context.availableWidth

            context.advanceY(view.thickness + view.padding)

            context.addOperation(.graphics(.line(
                from: PDF.Point(x: startX, y: lineY),
                to: PDF.Point(x: endX, y: lineY),
                color: view.color,
                width: view.thickness
            )))

            return PDF.Content()
        }
    }
}
