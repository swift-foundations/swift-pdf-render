import PDF_Standard

extension PDF.Context.List {

    public struct State: Sendable {

        public var stack: [(type: Kind, currentIndex: Int)] = []

        public var marker: (marker: Marker, x: PDF.UserSpace.X)?
        public init() {}
    }
}

extension PDF.Context.List.State {

    public var depth: Int { stack.count }
}
