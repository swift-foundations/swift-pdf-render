// PDF.Text.swift

public import PDF_Standard

extension PDF {
    /// Text element with automatic line wrapping.
    ///
    /// Style overrides are specified via a partial `PDF.Context.Style`. Properties set in
    /// the style override the context's style; nil properties inherit from context.
    ///
    /// ```swift
    /// // Simple text (inherits all style from context)
    /// PDF.Text("Hello, World!")
    ///
    /// // Text with style overrides
    /// PDF.Text("Bold heading", style: .init(font: .helveticaBold, fontSize: 24))
    ///
    /// // Using convenience initializer
    /// PDF.Text("Red text", font: .helvetica, fontSize: 12, color: .init(r: 1, g: 0, b: 0))
    /// ```
    public struct Text: Sendable {
        public typealias Content = Never

        /// The text to render.
        public var text: String

        /// Partial style overrides (nil properties inherit from context).
        public var style: PDF.Context.Style

        /// Create a text element with a partial style.
        ///
        /// - Parameters:
        ///   - text: The text to render.
        ///   - style: Partial style overrides. Defaults to `.empty` (inherit all from context).
        public init(_ text: String, style: PDF.Context.Style = .empty) {
            self.text = text
            self.style = style
        }

        /// Create a text element with individual style properties.
        ///
        /// Convenience initializer for common styling without constructing a `PDF.Context.Style`.
        ///
        /// - Parameters:
        ///   - text: The text to render.
        ///   - font: Font override (nil inherits from context).
        ///   - fontSize: Font size override (nil inherits from context).
        ///   - color: Color override (nil inherits from context).
        public init(
            _ text: String,
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Unit? = nil,
            color: PDF.Color? = nil
        ) {
            self.text = text
            self.style = PDF.Context.Style(font: font, fontSize: fontSize, color: color)
        }
    }
}
