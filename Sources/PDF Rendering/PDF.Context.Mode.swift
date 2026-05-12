// PDF.Context.Mode.swift
// Rendering mode flags.

extension PDF.Context {
    /// Rendering mode flags.
    public struct Mode: Sendable, Equatable {
        /// Preformatted mode - preserves whitespace in `<pre>` blocks.
        public var preserveWhitespace: Bool = false
        /// No-wrap mode - per CSS `white-space: nowrap` / `pre`; line-wrap on
        /// overflow is suppressed, content extends past `layout.box` width.
        public var noWrap: Bool = false
        /// Measurement mode - when true, operations are not added.
        public var measurement: Bool = false
        public init() {}
    }
}
