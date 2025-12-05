// Empty+PDF.View.swift
// PDF.View conformance for Empty

public import Renderable
public import PDF_Standard

extension Empty: PDF.View {
    public typealias Content = Never

    public static func _render(_ markup: Empty, context: inout PDF.Context) {
        // Produces no output
    }

    public var body: Never { fatalError() }
}
