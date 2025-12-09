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
    /// Total line height in points.
    ///
    /// Computed from fontSize × lineHeight multiplier.
    public var lineHeightPoints: PDF.UserSpace.Height {
        PDF.UserSpace.Height(fontSize * lineHeight.value)
    }

    /// Half-leading value using CSS half-leading model.
    ///
    /// The leading is the extra space beyond the font's natural content height
    /// (ascender - descender), distributed symmetrically above and below text.
    ///
    /// `halfLeading = max(0, (lineHeight - contentHeight) / 2)`
    public var halfLeading: PDF.UserSpace.Unit {
        let ascender = font.metrics.ascender(atSize: fontSize)
        let descender = font.metrics.descender(atSize: fontSize)  // negative
        let contentHeight = ascender - descender
        let lineHeight = fontSize * self.lineHeight.value
        return Swift.max(PDF.UserSpace.Unit(0), (lineHeight - contentHeight) / PDF.UserSpace.Unit(2))
    }

    /// Distance from top of line box to baseline.
    ///
    /// This equals: `halfLeading + ascender`
    ///
    /// Used to position text properly within a line box following
    /// the CSS half-leading model for symmetric spacing.
    public var baselineOffset: PDF.UserSpace.Unit {
        halfLeading + font.metrics.ascender(atSize: fontSize)
    }
}
