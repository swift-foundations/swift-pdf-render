// PDF.Context.Style.Resolved.swift
// Fully resolved style with concrete values.

import Geometry_Primitives
public import Layout_Primitives
public import PDF_Standard

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
            verticalOffset: PDF.UserSpace.Height = .init(0),
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
    /// Line box metrics computed from font and line height.
    public var line: Line { Line(style: self) }

    /// Line box metrics for text layout.
    public struct Line: Sendable {
        private let style: PDF.Context.Style.Resolved

        init(style: PDF.Context.Style.Resolved) {
            self.style = style
        }

        /// Total line height in points (fontSize × lineHeight multiplier).
        public var height: PDF.UserSpace.Height {
            style.fontSize.height * style.lineHeight
        }

        /// Half-leading value using CSS half-leading model.
        ///
        /// The leading is the extra space beyond the font's natural content height
        /// (ascender - descender), distributed symmetrically above and below text.
        public var halfLeading: PDF.UserSpace.Height {
            let ascender = style.font.metrics.ascender(atSize: style.fontSize)
            let descender = style.font.metrics.descender(atSize: style.fontSize)
            let contentHeight = ascender - descender
            return .max(.zero, (height - contentHeight) / 2)
        }

        /// Distance from top of line box to baseline.
        ///
        /// This equals: `halfLeading + ascender`
        public var baselineOffset: PDF.UserSpace.Height {
            halfLeading + style.font.metrics.ascender(atSize: style.fontSize)
        }
    }
}
