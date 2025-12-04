// PDF.Render.swift
// Internal rendering operations (not part of public API)

extension PDF {
    /// Internal namespace for rendering operations
    public enum Render {}
}

extension PDF.Render {
    /// Rendering operation
    public enum Operation: Sendable {
        case text(TextOperation)
        case graphics(GraphicsOperation)
    }

    /// Text rendering operation
    public struct TextOperation: Sendable {
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

    /// Graphics rendering operation
    public enum GraphicsOperation: Sendable {
        case line(from: PDF.UserSpace.Coordinate, to: PDF.UserSpace.Coordinate, color: PDF.Color, width: PDF.UserSpace.Width)
        case rectangle(PDF.UserSpace.Rectangle, fill: PDF.Color?, stroke: PDF.Color?, strokeWidth: PDF.UserSpace.Width)
    }
}
