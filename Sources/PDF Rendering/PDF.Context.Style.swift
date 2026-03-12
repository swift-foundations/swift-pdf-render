// PDF.Context.Style.swift
// Text styling as a product type with monoid structure.

import Geometry_Primitives
public import Layout_Primitives
public import PDF_Standard

extension PDF.Context {
    /// Text styling configuration for rendering.
    ///
    /// `Style` is a **product type** representing the styling dimensions of text rendering.
    /// It forms a **monoid** under the `combined(with:)` operation, allowing styles to be
    /// composed and merged in a principled way.
    ///
    /// ## Category-Theoretic Structure
    ///
    /// - **Product**: Style is a product of independent styling dimensions (font × fontSize × color × ...)
    /// - **Monoid**: (Style, combined, .default) where `combined` merges defined values
    /// - **Functor**: Each styling dimension can be independently transformed
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let base = PDF.Context.Style.default
    /// let heading = base
    ///     .with(font: .helveticaBold)
    ///     .with(fontSize: 24)
    ///     .with(color: .init(gray: 0.2))
    /// ```
    public struct Style: Sendable, Equatable {
        /// Font face
        public var font: PDF.Font?

        /// Font size in points
        public var fontSize: PDF.UserSpace.Size<1>?

        /// Text color
        public var color: PDF.Color?

        /// Line height multiplier (e.g., 1.2 for 120% line height)
        public var lineHeight: Scale<1, Double>?

        /// Text decoration (underline, strikethrough)
        public var textMarkup: PDF.Annotation.TextMarkup.Kind?

        /// Vertical offset for subscript/superscript
        public var verticalOffset: PDF.UserSpace.Height?

        /// Horizontal text alignment
        public var textAlign: Horizontal.Alignment?

        // MARK: - Initializers

        /// Create a style with all properties
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

// MARK: - Monoid Identity

extension PDF.Context.Style {
    /// The empty style (monoid identity).
    ///
    /// When combined with any style `s`, returns `s` unchanged:
    /// ```
    /// Style.empty.combined(with: s) == s
    /// s.combined(with: .empty) == s
    /// ```
    public static let empty = PDF.Context.Style()

    /// Default style with concrete values for rendering.
    ///
    /// Unlike `empty`, this provides actual defaults for all properties.
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

// MARK: - Monoid Operation

extension PDF.Context.Style {
    /// Combine two styles, with `other`'s defined values taking precedence.
    ///
    /// This is the monoid binary operation. It satisfies:
    /// - **Identity**: `empty.combined(with: s) == s` and `s.combined(with: .empty) == s`
    /// - **Associativity**: `(a.combined(with: b)).combined(with: c) == a.combined(with: b.combined(with: c))`
    ///
    /// - Parameter other: The style to overlay on top of this style
    /// - Returns: A new style with `other`'s non-nil values overriding this style's values
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

    /// Combine an array of styles from left to right.
    ///
    /// Later styles override earlier ones for any defined property.
    ///
    /// - Parameter styles: Styles to combine
    /// - Returns: The combined style
    public static func combined(_ styles: [PDF.Context.Style]) -> PDF.Context.Style {
        styles.reduce(.empty) { $0.combined(with: $1) }
    }

    /// Combine multiple styles from left to right.
    public static func combined(_ styles: PDF.Context.Style...) -> PDF.Context.Style {
        combined(styles)
    }
}

// MARK: - Fluent Modifiers (Endomorphisms)

extension PDF.Context.Style {
    /// Return a new style with the font changed.
    @inlinable
    public func with(font: PDF.Font) -> PDF.Context.Style {
        var copy = self
        copy.font = font
        return copy
    }

    /// Return a new style with the font size changed.
    @inlinable
    public func with(fontSize: PDF.UserSpace.Size<1>) -> PDF.Context.Style {
        var copy = self
        copy.fontSize = fontSize
        return copy
    }

    /// Return a new style with the color changed.
    @inlinable
    public func with(color: PDF.Color) -> PDF.Context.Style {
        var copy = self
        copy.color = color
        return copy
    }

    /// Return a new style with the line height changed.
    @inlinable
    public func with(lineHeight: Scale<1, Double>) -> PDF.Context.Style {
        var copy = self
        copy.lineHeight = lineHeight
        return copy
    }

    /// Return a new style with text markup changed.
    @inlinable
    public func with(textMarkup: PDF.Annotation.TextMarkup.Kind?) -> PDF.Context.Style {
        var copy = self
        copy.textMarkup = textMarkup
        return copy
    }

    /// Return a new style with vertical offset changed.
    @inlinable
    public func with(verticalOffset: PDF.UserSpace.Height) -> PDF.Context.Style {
        var copy = self
        copy.verticalOffset = verticalOffset
        return copy
    }

    /// Return a new style with text alignment changed.
    @inlinable
    public func with(textAlign: Horizontal.Alignment) -> PDF.Context.Style {
        var copy = self
        copy.textAlign = textAlign
        return copy
    }
}

// MARK: - Resolution

extension PDF.Context.Style {
    /// Resolve this style against defaults, producing a fully-specified style.
    ///
    /// - Parameter defaults: The default values to use for any nil properties
    /// - Returns: A resolved style with all properties defined
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

// MARK: - Conversion from Resolved

extension PDF.Context.Style {
    /// Create a partial style from a resolved style.
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
