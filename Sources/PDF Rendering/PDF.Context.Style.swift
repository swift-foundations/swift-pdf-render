import Geometry_Primitives
public import Layout_Primitives
public import PDF_Standard

extension PDF.Context {

    public struct Style: Sendable, Equatable {

        public var font: PDF.Font?

        public var fontSize: PDF.UserSpace.Size<1>?

        public var color: PDF.Color?

        public var lineHeight: Scale<1, Double>?

        public var textMarkup: PDF.Annotation.TextMarkup.Kind?

        public var verticalOffset: PDF.UserSpace.Height?

        public var textAlign: Horizontal.Alignment?

        public init(
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Size<1>? = nil,
            color: PDF.Color? = nil,
            lineHeight: Scale<1, Double>? = nil,
            textMarkup: PDF.Annotation.TextMarkup.Kind? = nil,
            verticalOffset: PDF.UserSpace.Height? = nil,
            textAlign: Horizontal.Alignment? = nil
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

extension PDF.Context.Style {

    public static let empty = PDF.Context.Style()

    public static let `default` = PDF.Context.Style(
        font: .helvetica,
        fontSize: 12,
        color: .black,
        lineHeight: 1.2,
        textMarkup: nil,
        verticalOffset: .init(0),
        textAlign: .leading
    )
}

extension PDF.Context.Style {

    public func combined(with other: PDF.Context.Style) -> PDF.Context.Style {
        PDF.Context.Style(
            font: other.font ?? self.font,
            fontSize: other.fontSize ?? self.fontSize,
            color: other.color ?? self.color,
            lineHeight: other.lineHeight ?? self.lineHeight,
            textMarkup: other.textMarkup ?? self.textMarkup,
            verticalOffset: other.verticalOffset ?? self.verticalOffset,
            textAlign: other.textAlign ?? self.textAlign
        )
    }

    public static func combined(_ styles: [PDF.Context.Style]) -> PDF.Context.Style {
        styles.reduce(.empty) { $0.combined(with: $1) }
    }

    public static func combined(_ styles: PDF.Context.Style...) -> PDF.Context.Style {
        combined(styles)
    }
}

extension PDF.Context.Style {

    @inlinable
    public func with(font: PDF.Font) -> PDF.Context.Style {
        var copy = self
        copy.font = font
        return copy
    }

    @inlinable
    public func with(fontSize: PDF.UserSpace.Size<1>) -> PDF.Context.Style {
        var copy = self
        copy.fontSize = fontSize
        return copy
    }

    @inlinable
    public func with(color: PDF.Color) -> PDF.Context.Style {
        var copy = self
        copy.color = color
        return copy
    }

    @inlinable
    public func with(lineHeight: Scale<1, Double>) -> PDF.Context.Style {
        var copy = self
        copy.lineHeight = lineHeight
        return copy
    }

    @inlinable
    public func with(textMarkup: PDF.Annotation.TextMarkup.Kind?) -> PDF.Context.Style {
        var copy = self
        copy.textMarkup = textMarkup
        return copy
    }

    @inlinable
    public func with(verticalOffset: PDF.UserSpace.Height) -> PDF.Context.Style {
        var copy = self
        copy.verticalOffset = verticalOffset
        return copy
    }

    @inlinable
    public func with(textAlign: Horizontal.Alignment) -> PDF.Context.Style {
        var copy = self
        copy.textAlign = textAlign
        return copy
    }
}

extension PDF.Context.Style {

    public func resolved(
        against defaults: Resolved = .init(
            font: .helvetica,
            fontSize: 12,
            color: .black,
            lineHeight: 1.2,
            textMarkup: nil,
            verticalOffset: .init(0),
            textAlign: .leading
        )
    ) -> Resolved {
        Resolved(
            font: font ?? defaults.font,
            fontSize: fontSize ?? defaults.fontSize,
            color: color ?? defaults.color,
            lineHeight: lineHeight ?? defaults.lineHeight,
            textMarkup: textMarkup ?? defaults.textMarkup,
            verticalOffset: verticalOffset ?? defaults.verticalOffset,
            textAlign: textAlign ?? defaults.textAlign
        )
    }
}

extension PDF.Context.Style {

    public init(_ resolved: Resolved) {
        self.init(
            font: resolved.font,
            fontSize: resolved.fontSize,
            color: resolved.color,
            lineHeight: resolved.lineHeight,
            textMarkup: resolved.textMarkup,
            verticalOffset: resolved.verticalOffset,
            textAlign: resolved.textAlign
        )
    }
}
