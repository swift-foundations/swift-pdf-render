import Layout_Primitives
public import PDF_Standard

extension PDF.Context {

    public struct Scope: Sendable {
        public let style: Style.Resolved
        public let llx: PDF.UserSpace.X
        public let preserveWhitespace: Bool
        public let noWrap: Bool
        public let linkURL: String?
    }
}
