extension Never: PDF.View {
    public typealias Content = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        fatalError("Never cannot be rendered")
    }
}
