// _Tuple+PDF.View.swift
// PDF.View conformance for _Tuple

public import Renderable
public import PDF_Standard

extension _Tuple: @retroactive Renderable where repeat each Content: PDF.View {
    public typealias Context = PDF.Context
    public typealias Content = Never
    public typealias Output = PDF.Render.Operation
    public var body: Never { fatalError() }

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        func render<T: PDF.View>(_ element: T) {
            T._render(element, into: &buffer, context: &context)
        }
        repeat render(each view.content)
    }
}

extension _Tuple: PDF.View where repeat each Content: PDF.View {}
