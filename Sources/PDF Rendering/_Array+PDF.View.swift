// _Array+PDF.View.swift
// PDF.View conformance for _Array

public import Renderable
public import PDF_Standard

extension _Array: @retroactive Renderable where Element: PDF.View {
    public typealias Context = PDF.Context
    public typealias Content = Never
    public typealias Output = PDF.Render.Operation
    public var body: Never { fatalError() }

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        for element in view.elements {
            Element._render(element, into: &buffer, context: &context)
        }
    }
}

extension _Array: PDF.View where Element: PDF.View {}
