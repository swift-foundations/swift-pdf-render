// PDF.Style.swift
// Text styling as a product type with monoid structure.

public import PDF_Standard

extension PDF {
    /// Text styling configuration.
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
    /// let base = PDF.Style.default
    /// let heading = base
    ///     .with(font: .helveticaBold)
    ///     .with(fontSize: 24)
    ///     .with(color: .init(gray: 0.2))
    /// ```
    public struct Style: Sendable, Equatable {
        /// Font face
        public var font: PDF.Font?

        /// Font size in points
        public var fontSize: PDF.UserSpace.Unit?

        /// Text color
        public var color: PDF.Color?

        /// Line height multiplier (e.g., 1.2 for 120% line height)
        public var lineHeight: Double?

        /// Text decoration (underline, strikethrough)
        public var textMarkup: PDF.TextMarkup?

        /// Vertical offset for subscript/superscript
        public var verticalOffset: PDF.UserSpace.Unit?

        // MARK: - Initializers

        /// Create a style with all properties
        public init(
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Unit? = nil,
            color: PDF.Color? = nil,
            lineHeight: Double? = nil,
            textMarkup: PDF.TextMarkup? = nil,
            verticalOffset: PDF.UserSpace.Unit? = nil
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

// MARK: - Monoid Identity

extension PDF.Style {
    /// The empty style (monoid identity).
    ///
    /// When combined with any style `s`, returns `s` unchanged:
    /// ```
    /// Style.empty.combined(with: s) == s
    /// s.combined(with: .empty) == s
    /// ```
    public static let empty = PDF.Style()

    /// Default style with concrete values for rendering.
    ///
    /// Unlike `empty`, this provides actual defaults for all properties.
    public static let `default` = PDF.Style(
        font: .helvetica,
        fontSize: 12,
        color: .black,
        lineHeight: 1.2,
        textMarkup: nil,
        verticalOffset: 0
    )
}

// MARK: - Monoid Operation

extension PDF.Style {
    /// Combine two styles, with `other`'s defined values taking precedence.
    ///
    /// This is the monoid binary operation. It satisfies:
    /// - **Identity**: `empty.combined(with: s) == s` and `s.combined(with: .empty) == s`
    /// - **Associativity**: `(a.combined(with: b)).combined(with: c) == a.combined(with: b.combined(with: c))`
    ///
    /// - Parameter other: The style to overlay on top of this style
    /// - Returns: A new style with `other`'s non-nil values overriding this style's values
    public func combined(with other: PDF.Style) -> PDF.Style {
        PDF.Style(
            font: other.font ?? self.font,
            fontSize: other.fontSize ?? self.fontSize,
            color: other.color ?? self.color,
            lineHeight: other.lineHeight ?? self.lineHeight,
            textMarkup: other.textMarkup ?? self.textMarkup,
            verticalOffset: other.verticalOffset ?? self.verticalOffset
        )
    }

    /// Combine an array of styles from left to right.
    ///
    /// Later styles override earlier ones for any defined property.
    ///
    /// - Parameter styles: Styles to combine
    /// - Returns: The combined style
    public static func combined(_ styles: [PDF.Style]) -> PDF.Style {
        styles.reduce(.empty) { $0.combined(with: $1) }
    }

    /// Combine multiple styles from left to right.
    public static func combined(_ styles: PDF.Style...) -> PDF.Style {
        combined(styles)
    }
}

// MARK: - Fluent Modifiers (Endomorphisms)

extension PDF.Style {
    /// Return a new style with the font changed.
    @inlinable
    public func with(font: PDF.Font) -> PDF.Style {
        var copy = self
        copy.font = font
        return copy
    }

    /// Return a new style with the font size changed.
    @inlinable
    public func with(fontSize: PDF.UserSpace.Unit) -> PDF.Style {
        var copy = self
        copy.fontSize = fontSize
        return copy
    }

    /// Return a new style with the color changed.
    @inlinable
    public func with(color: PDF.Color) -> PDF.Style {
        var copy = self
        copy.color = color
        return copy
    }

    /// Return a new style with the line height changed.
    @inlinable
    public func with(lineHeight: Double) -> PDF.Style {
        var copy = self
        copy.lineHeight = lineHeight
        return copy
    }

    /// Return a new style with text markup changed.
    @inlinable
    public func with(textMarkup: PDF.TextMarkup?) -> PDF.Style {
        var copy = self
        copy.textMarkup = textMarkup
        return copy
    }

    /// Return a new style with vertical offset changed.
    @inlinable
    public func with(verticalOffset: PDF.UserSpace.Unit) -> PDF.Style {
        var copy = self
        copy.verticalOffset = verticalOffset
        return copy
    }
}

// MARK: - Resolution

extension PDF.Style {
    /// Resolve this style against defaults, producing a fully-specified style.
    ///
    /// - Parameter defaults: The default values to use for any nil properties
    /// - Returns: A resolved style with all properties defined
    public func resolved(against defaults: Resolved = .init(
        font: .helvetica,
        fontSize: 12,
        color: .black,
        lineHeight: 1.2,
        textMarkup: nil,
        verticalOffset: 0
    )) -> Resolved {
        Resolved(
            font: font ?? defaults.font,
            fontSize: fontSize ?? defaults.fontSize,
            color: color ?? defaults.color,
            lineHeight: lineHeight ?? defaults.lineHeight,
            textMarkup: textMarkup ?? defaults.textMarkup,
            verticalOffset: verticalOffset ?? defaults.verticalOffset
        )
    }
}

// MARK: - Conversion from Resolved

extension PDF.Style {
    /// Create a partial style from a resolved style.
    public init(_ resolved: Resolved) {
        self.init(
            font: resolved.font,
            fontSize: resolved.fontSize,
            color: resolved.color,
            lineHeight: resolved.lineHeight,
            textMarkup: resolved.textMarkup,
            verticalOffset: resolved.verticalOffset
        )
    }
}
