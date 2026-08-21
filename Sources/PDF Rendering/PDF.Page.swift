extension PDF.Page {

    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle,
        contentStream: ISO_32000.ContentStream,
        annotations: [PDF.Annotation] = []
    ) {
        var fontResources: [ISO_32000.COS.Name: ISO_32000.Font] = [:]
        for font in contentStream.fontsUsed {
            fontResources[font.resourceName] = font
        }

        var imageResources: [ISO_32000.COS.Name: ISO_32000.Image] = [:]
        for image in contentStream.imagesUsed {
            imageResources[image.resourceName] = image
        }

        self.init(
            mediaBox: mediaBox,
            content: contentStream,
            resources: ISO_32000.Resources(fonts: fontResources, xObjects: imageResources),
            annotations: annotations
        )
    }
}
