public import PDF_Standard
public import Render_Primitives

extension Render.Empty: PDF.View {
    public typealias Content = Never

    public static func _render(_ markup: Render.Empty, context: inout PDF.Context) {

    }

    public var body: Never { fatalError("Empty uses direct rendering") }
}
