extension PDF.Context {

    public struct Inline: Sendable {

        public var runs: [PDF.Context.Text.Run] = []
        public init() {}
    }
}

extension PDF.Context.Inline {

    public var hasRuns: Bool { !runs.isEmpty }
}
