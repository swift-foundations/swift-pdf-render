// _Conditional+PDF.View.swift
// PDF.View conformance for _Conditional

public import Renderable
public import PDF_Standard

extension _Conditional: @retroactive Renderable where First: PDF.View, Second: PDF.View {
    public typealias Context = PDF.Context
    public typealias Content = Never
    public typealias Output = PDF.Render.Operation
    public var body: Never { fatalError() }

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        switch view {
        case .first(let first):
            First._render(first, into: &buffer, context: &context)
        case .second(let second):
            Second._render(second, into: &buffer, context: &context)
        }
    }
}

extension _Conditional: PDF.View where First: PDF.View, Second: PDF.View {}
