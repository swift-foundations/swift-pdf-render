import PDF_Standard

extension PDF.Context {

    public struct Margin: Sendable, Equatable {
        public var top: PDF.UserSpace.Height?
        public var right: PDF.UserSpace.Width?
        public var bottom: PDF.UserSpace.Height?
        public var left: PDF.UserSpace.Width?
        public init() {}
    }
}
