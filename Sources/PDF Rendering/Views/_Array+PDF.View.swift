// _Array+PDF.View.swift
// PDF.View conformance for _Array

public import Rendering
public import PDF_Standard

extension _Array: PDF.View where Element: PDF.View {
    public typealias Content = Never

    public var body: Never { fatalError() }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        for element in view.elements {
            Element._render(element, context: &context)
        }
    }
}
