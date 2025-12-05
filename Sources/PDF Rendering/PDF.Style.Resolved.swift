// PDF.Style.Resolved.swift
// Fully resolved style with concrete values.

public import PDF_Standard
import Geometry

extension PDF.Style {
    /// A style with all properties resolved to concrete values.
    ///
    /// Unlike `Style`, this cannot have nil values and is ready for rendering.
    public struct Resolved: Sendable, Equatable {
        public var font: PDF.Font
        public var fontSize: PDF.UserSpace.Unit
        public var color: PDF.Color
        public var lineHeight: Scale<1>
        public var textMarkup: PDF.TextMarkup?
        public var verticalOffset: PDF.UserSpace.Unit

        public init(
            font: PDF.Font,
            fontSize: PDF.UserSpace.Unit,
            color: PDF.Color,
            lineHeight: Scale<1>,
            textMarkup: PDF.TextMarkup? = nil,
            verticalOffset: PDF.UserSpace.Unit = 0
        ) {
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.lineHeight = lineHeight
            self.textMarkup = textMarkup
            self.verticalOffset = verticalOffset
        }
    }
}

extension PDF.Style.Resolved {
    /// Line height in points
    public var lineHeightPoints: PDF.UserSpace.Height {
        .init(fontSize * lineHeight.value)
    }
}
