// Empty+PDF.View.swift
// PDF.View conformance for Empty

public import PDF_Standard
public import Rendering_Primitives

extension Rendering.Empty: PDF.View {
    public typealias Content = Never

    public static func _render(_ markup: Rendering.Empty, context: inout PDF.Context) {
        // Produces no output
    }

    public var body: Never { fatalError("Empty uses direct rendering") }
}
