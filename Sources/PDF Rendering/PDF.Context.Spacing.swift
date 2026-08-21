import PDF_Standard

extension PDF.Context {

    public struct Spacing: Sendable, Equatable {

        public var vertical: PDF.UserSpace.Height?

        public var horizontal: PDF.UserSpace.Width?
        public init() {}
    }
}

extension PDF.Context.Spacing {

    public var isHorizontal: Bool { horizontal != nil }
}
