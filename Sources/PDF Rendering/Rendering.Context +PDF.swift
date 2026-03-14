import Rendering_Primitives
public import PDF_Standard

extension Rendering.Context {
    /// Creates a rendering context that forwards semantic operations to a PDF context.
    ///
    /// - Parameter state: A mutable reference to the PDF rendering state.
    /// - Returns: A witness-based rendering context backed by the PDF context.
    public static func pdf(state: Ownership.Mutable<PDF.Context>) -> Self {
        .init(
            text: { state.value.text($0) },
            lineBreak: { state.value.lineBreak() },
            thematicBreak: { state.value.thematicBreak() },
            image: { state.value.image(source: $0, alt: $1) },
            pageBreak: { state.value.pageBreak() },
            pushBlock: { PDF.Context._pushBlock(&state.value, role: $0, style: $1) },
            popBlock: { PDF.Context._popBlock(&state.value) },
            pushInline: { PDF.Context._pushInline(&state.value, role: $0, style: $1) },
            popInline: { PDF.Context._popInline(&state.value) },
            pushList: { PDF.Context._pushList(&state.value, kind: $0, start: $1) },
            popList: { PDF.Context._popList(&state.value) },
            pushItem: { PDF.Context._pushItem(&state.value) },
            popItem: { PDF.Context._popItem(&state.value) },
            pushLink: { PDF.Context._pushLink(&state.value, destination: $0) },
            popLink: { PDF.Context._popLink(&state.value) }
        )
    }
}
