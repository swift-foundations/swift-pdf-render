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
            break: .init(
                line: { state.value.lineBreak() },
                thematic: { state.value.thematicBreak() },
                page: { state.value.pageBreak() }
            ),
            image: { state.value.image(source: $0, alt: $1) },
            push: .init(
                block: { PDF.Context._pushBlock(&state.value, role: $0, style: $1) },
                inline: { PDF.Context._pushInline(&state.value, role: $0, style: $1) },
                list: { PDF.Context._pushList(&state.value, kind: $0, start: $1) },
                item: { PDF.Context._pushItem(&state.value) },
                link: { PDF.Context._pushLink(&state.value, destination: $0) }
            ),
            pop: .init(
                block: { PDF.Context._popBlock(&state.value) },
                inline: { PDF.Context._popInline(&state.value) },
                list: { PDF.Context._popList(&state.value) },
                item: { PDF.Context._popItem(&state.value) },
                link: { PDF.Context._popLink(&state.value) }
            )
        )
    }
}
