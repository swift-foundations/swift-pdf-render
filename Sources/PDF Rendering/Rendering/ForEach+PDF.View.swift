// ForEach+PDF.View.swift
// PDF.View conformance for ForEach — delegates to Array rendering.

public import PDF_Standard
public import Rendering_Primitives

extension Rendering.ForEach: PDF.View where Content: PDF.View {
    public var body: [Content] {
        content
    }

    public static func _render(_ view: Self, context: inout PDF.Context) {
        [Content]._render(view.content, context: &context)
    }
}
