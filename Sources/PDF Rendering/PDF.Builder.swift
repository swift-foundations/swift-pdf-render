public import PDF_Standard
public import Render_Primitives

public typealias BuilderRaw = Render.Builder

extension PDF {

    public typealias Builder = BuilderRaw
}

extension BuilderRaw {

    public static func buildBlock() -> Render.Empty {
        Render.Empty()
    }
}
