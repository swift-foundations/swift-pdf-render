// PDF.Context.Style.Resolved.swift
// Fully resolved style with concrete values.

public import PDF_Standard
import Geometry

extension PDF.Context.Style {
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

extension PDF.Context.Style.Resolved {
    /// Line box for current style using CSS half-leading model.
    ///
    /// This computes proper line box geometry that distributes extra space
    /// symmetrically above and below text, following CSS inline formatting.
    ///
    /// The line box provides:
    /// - `height`: Total line box height
    /// - `baselineOffset`: Distance from line box top to baseline (halfLeading + ascender)
    /// - `halfLeading`: Space distributed symmetrically above/below text
    public var lineBox: ISO_32000.LineBox {
        ISO_32000.LineBox(
            metrics: font.metrics,
            fontSize: fontSize,
            lineHeightMultiplier: lineHeight.value
        )
    }

    /// Line height in points (total line box height)
    ///
    /// This property is preserved for backwards compatibility.
    /// Consider using `lineBox.height` for more explicit semantics.
    public var lineHeightPoints: PDF.UserSpace.Height {
        lineBox.height
    }
}
