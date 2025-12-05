// Optional+PDF.View.swift
// PDF.View conformance for Optional

public import PDF_Standard

extension Optional: PDF.View where Wrapped: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError() }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        if let wrapped = view {
            Wrapped._render(wrapped, context: &context)
        }
    }
}
