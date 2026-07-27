// PDF.Context.Inline.swift
// Inline text run accumulator.

extension PDF.Context {
    /// Accumulated inline text runs for batched rendering.
    public struct Inline: Sendable {
        /// Accumulated inline text runs.
        public var runs: [PDF.Context.Text.Run] = []
        public init() {}
    }
}

extension PDF.Context.Inline {
    /// Whether there are pending inline runs.
    public var hasRuns: Bool { !runs.isEmpty }
}
