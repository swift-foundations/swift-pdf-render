import PDF_Standard

extension PDF.Context {

    public struct Row: Sendable, Equatable {

        internal var lastX: PDF.UserSpace.X?

        internal var startY: PDF.UserSpace.Y?

        internal var maxY: PDF.UserSpace.Y?
        public init() {}
    }
}
