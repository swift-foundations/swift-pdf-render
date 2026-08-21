import PDF_Standard

extension PDF.Context {

    public struct Layout: Sendable, Equatable {

        public var box: PDF.UserSpace.Rectangle

        internal var initial: PDF.UserSpace.Rectangle

        internal var maxY: PDF.UserSpace.Y
    }
}
