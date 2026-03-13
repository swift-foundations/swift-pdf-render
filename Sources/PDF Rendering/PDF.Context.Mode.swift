// PDF.Context.Mode.swift
// Rendering mode flags.

extension PDF.Context {
    /// Rendering mode flags.
    public struct Mode: Sendable, Equatable {
        /// Preformatted mode - preserves whitespace in `<pre>` blocks.
        public var preserveWhitespace: Bool = false
        /// Measurement mode - when true, operations are not added.
        public var measurement: Bool = false
        public init() {}
    }
}
