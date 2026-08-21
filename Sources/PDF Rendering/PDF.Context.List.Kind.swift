extension PDF.Context.List {

    public enum Kind: Sendable {
        case unordered
        case ordered(startNumber: Int)
    }
}
