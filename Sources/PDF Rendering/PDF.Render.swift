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
        public var position: PDF.Point
        public var font: PDF.Font
        public var size: Double
        public var color: PDF.Color

        public init(
            text: String,
            position: PDF.Point,
            font: PDF.Font,
            size: Double,
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
        case line(from: PDF.Point, to: PDF.Point, color: PDF.Color, width: Double)
        case rectangle(PDF.Rect, fill: PDF.Color?, stroke: PDF.Color?, strokeWidth: Double)
    }
}
