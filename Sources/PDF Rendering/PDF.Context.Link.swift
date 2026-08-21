import PDF_Standard

extension PDF.Context {

    public struct Link: Sendable, Equatable {

        public var pending: [Pending] = []

        internal var url: String?
        public init() {}
    }
}
