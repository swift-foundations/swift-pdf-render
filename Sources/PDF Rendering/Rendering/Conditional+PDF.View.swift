// Conditional+PDF.View.swift
// PDF.View conformance for Conditional

public import PDF_Standard
public import Render_Primitives

extension Render.Conditional: PDF.View where First: PDF.View, Second: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError("Conditional uses direct rendering") }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        switch view {
        case .first(let first):
            First._render(first, context: &context)

        case .second(let second):
            Second._render(second, context: &context)
        }
    }
}
