// PDF.Render.Operation.swift
// Rendering operations (text and graphics).

public import PDF_Standard

extension PDF.Render {
    /// A rendering operation (text or graphics).
    public enum Operation: Sendable, Equatable {
        case text(Text)
        case graphics(Graphics)
    }
}

extension PDF.Render.Operation {
    /// Text rendering operation.
    public struct Text: Sendable, Equatable {
        public var text: String
        public var position: PDF.UserSpace.Coordinate
        public var font: PDF.Font
        public var size: PDF.UserSpace.Unit
        public var color: PDF.Color

        public init(
            text: String,
            position: PDF.UserSpace.Coordinate,
            font: PDF.Font,
            size: PDF.UserSpace.Unit,
            color: PDF.Color
        ) {
            self.text = text
            self.position = position
            self.font = font
            self.size = size
            self.color = color
        }
    }
}

extension PDF.Render.Operation {
    /// Graphics rendering operation.
    public enum Graphics: Sendable, Equatable {
        case line(
            from: PDF.UserSpace.Coordinate,
            to: PDF.UserSpace.Coordinate,
            color: PDF.Color,
            width: PDF.UserSpace.Width
        )
        case rectangle(
            PDF.UserSpace.Rectangle,
            fill: PDF.Color?,
            stroke: PDF.Color?,
            strokeWidth: PDF.UserSpace.Width
        )
    }
}
