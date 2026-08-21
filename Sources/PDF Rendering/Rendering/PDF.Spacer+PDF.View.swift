public import PDF_Standard

extension PDF {

    public struct Spacer: PDF.View, Sendable {

        public var height: PDF.UserSpace.Height

        public init(_ height: PDF.UserSpace.Height) {
            self.height = height
        }
    }
}

extension PDF.Spacer {
    public typealias Content = Never

    public var body: Never {
        fatalError("PDF.Spacer is a leaf view")
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        context.advance(view.height)

    }
}
