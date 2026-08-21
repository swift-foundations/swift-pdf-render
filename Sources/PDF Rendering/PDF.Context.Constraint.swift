import PDF_Standard

extension PDF.Context {

    public struct Constraint: Sendable, Equatable {
        public var width: PDF.UserSpace.Width?
        public var height: PDF.UserSpace.Height?
        public init() {}
    }
}
