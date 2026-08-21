import ISO_32000_Flate
public import PDF_Standard

extension PDF.Document {

    public init<View: PDF.View>(
        configuration: PDF.Configuration = .init(),
        @PDF.Builder _ build: () -> View
    ) {
        var context = PDF.Context(configuration)

        let view = build()
        View._render(view, context: &context)

        let viewer: ISO_32000.Viewer? =
            configuration.viewer == .init()
            ? nil
            : configuration.viewer

        self.init(
            version: configuration.version,
            info: configuration.info,
            pages: context.pages,
            viewer: viewer
        )
    }
}
