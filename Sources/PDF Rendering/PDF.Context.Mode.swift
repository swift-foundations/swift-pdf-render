extension PDF.Context {

    public struct Mode: Sendable, Equatable {

        public var preserveWhitespace: Bool = false

        public var noWrap: Bool = false

        public var measurement: Bool = false

        public var pageBreaks: Int = 0
        public init() {}
    }
}
