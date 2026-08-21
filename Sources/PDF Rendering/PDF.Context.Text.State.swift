import PDF_Standard

extension PDF.Context.Text {

    public struct State: Sendable, Equatable {

        internal var blockOpen: Bool = false

        internal var font: PDF.Font? = nil

        internal var fontSize: PDF.UserSpace.Size<1>? = nil

        internal var color: PDF.Color? = nil

        internal var position: PDF.UserSpace.Coordinate? = nil
        public init() {}
    }
}
