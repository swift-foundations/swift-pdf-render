public import PDF_Standard

extension PDF {

    public protocol View {
        associatedtype Content: PDF.View

        @PDF.Builder var body: Content { get }

        static func _render(_ view: Self, context: inout PDF.Context)
    }
}

extension PDF.View where Content: PDF.View {

    @inlinable
    @_disfavoredOverload
    public static func _render(_ view: Self, context: inout PDF.Context) {
        Content._render(view.body, context: &context)
    }
}

extension PDF.View {

    public func render(context: inout PDF.Context) {
        Self._render(self, context: &context)
    }
}
