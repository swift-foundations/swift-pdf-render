// PDF.Context.Style.Resolved.swift
// Fully resolved style with concrete values.

public import PDF_Standard
import Geometry
public import Layout

extension PDF.Context.Style {
    /// A style with all properties resolved to concrete values.
    ///
    /// Unlike `Style`, this cannot have nil values and is ready for rendering.
    public struct Resolved: Sendable, Equatable {
        public var font: PDF.Font
        public var fontSize: PDF.UserSpace.Size<1>
        public var color: PDF.Color
        public var lineHeight: Scale<1, Double>
        public var textMarkup: PDF.Annotation.TextMarkup.Kind?
        public var verticalOffset: PDF.UserSpace.Height
        public var textAlign: Horizontal.Alignment

        public init(
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            lineHeight: Scale<1, Double>,
            textMarkup: PDF.Annotation.TextMarkup.Kind? = nil,
            verticalOffset: PDF.UserSpace.Height = 0,
            textAlign: Horizontal.Alignment = .leading
        ) {
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.lineHeight = lineHeight
            self.textMarkup = textMarkup
            self.verticalOffset = verticalOffset
            self.textAlign = textAlign
        }
    }
}

extension PDF.Context.Style.Resolved {
    /// Total line height in points.
    ///
    /// Computed from fontSize × lineHeight multiplier.
    public var lineHeightPoints: PDF.UserSpace.Height {
        fontSize.height * lineHeight.value
    }

    /// Half-leading value using CSS half-leading model.
    ///
    /// The leading is the extra space beyond the font's natural content height
    /// (ascender - descender), distributed symmetrically above and below text.
    ///
    /// `halfLeading = max(0, (lineHeight - contentHeight) / 2)`
    public var halfLeading: PDF.UserSpace.Height {
        let ascender = font.metrics.ascender(atSize: fontSize)
        let descender = font.metrics.descender(atSize: fontSize)  // negative
        let contentHeight = ascender - descender
        let lineHeightPts = fontSize.height * self.lineHeight.value
        return PDF.UserSpace.Height(max(0, (lineHeightPts.value - contentHeight.value) / 2.0))
    }

    /// Distance from top of line box to baseline.
    ///
    /// This equals: `halfLeading + ascender`
    ///
    /// Used to position text properly within a line box following
    /// the CSS half-leading model for symmetric spacing.
    public var baselineOffset: PDF.UserSpace.Height {
        halfLeading + font.metrics.ascender(atSize: fontSize)
    }
}
