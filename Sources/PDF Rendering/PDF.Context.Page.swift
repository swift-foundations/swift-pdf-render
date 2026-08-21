import Geometry_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {

    public enum Page {}

    public var page: Property<Page, Self> {
        get { Property(self) }
        _modify {
            var property = Property<Page, Self>(self)
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property where Tag == PDF.Context.Page, Base == PDF.Context {

    public mutating func new() {
        if base.mode.measurement {
            base.mode.pageBreaks += 1
            base.layout.box.lly = base.layout.initial.lly
            return
        }

        base.flush.text()

        let currentStream = ISO_32000.ContentStream(
            data: base.currentPageBuilder.data,
            fontsUsed: base.currentPageBuilder.fontsUsed,
            imagesUsed: base.currentPageBuilder.imagesUsed
        )
        let page = PDF.Page(
            mediaBox: base.mediaBox,
            contentStream: currentStream,
            annotations: base.currentPageAnnotations
        )
        base.completedPages.append(page)

        base.currentPageBuilder = .init()
        base.currentPageAnnotations = []

        base.layout.box.lly = base.layout.initial.lly
    }

    @discardableResult
    public mutating func ensure(height: PDF.UserSpace.Height) -> Bool {
        if exceeds(adding: height) {
            new()
            return true
        }
        return false
    }

    public func exceeds(adding height: PDF.UserSpace.Height) -> Bool {
        base.layout.box.lly + height > base.layout.maxY
    }

    public var isEmpty: Bool {
        base.currentPageBuilder.data.isEmpty
            && !base.text.blockOpen
            && base.inline.runs.isEmpty
    }
}
