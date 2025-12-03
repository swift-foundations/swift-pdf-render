// Empty+PDF.View.swift
// PDF.View conformance for Empty

public import Renderable
public import PDF_Standard

extension Empty: @retroactive Renderable {
    public typealias Content = Never
    public typealias Context = PDF.Context
    public typealias Output = PDF.Render.Operation

    public static func _render<Buffer: RangeReplaceableCollection>(
        _ markup: Empty,
        into buffer: inout Buffer,
        context: inout PDF.Context
    ) where Buffer.Element == PDF.Render.Operation {
        // Produces no output
    }

    public var body: Never { fatalError() }
}

extension Empty: PDF.View {}
