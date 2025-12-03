// Optional+PDF.View.swift
// PDF.View conformance for Optional

public import Renderable
public import PDF_Standard

extension Optional: @retroactive Renderable where Wrapped: PDF.View {
    public typealias Context = PDF.Context
    public typealias Content = Never
    public typealias Output = PDF.Render.Operation
    public var body: Never { fatalError() }

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ view: Self,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        if let wrapped = view {
            Wrapped._render(wrapped, into: &buffer, context: &context)
        }
    }
}

extension Optional: PDF.View where Wrapped: PDF.View {}
