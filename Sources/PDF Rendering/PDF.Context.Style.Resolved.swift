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
    /// Line box geometry computed from font metrics and line height multiplier.
    public var line: PDF.Layout.Line.Box {
        .init(
            ascender: font.metrics.ascender(atSize: fontSize),
            descender: (-font.metrics.descender(atSize: fontSize)),
            height: fontSize.height * lineHeight
        )
    }
}
