// PDF.Context.Page.swift
// Verb-as-property accessor for page operations

import Geometry_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {
    /// Tag for page operations.
    public enum Page {}

    /// Page operations for pagination.
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
    /// Start a new page, building the current page and resetting state.
    public mutating func new() {
        // Close any open text block before finalizing page
        base.flush.text()

        // Build current page
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

        // Reset for new page
        base.currentPageBuilder = .init()
        base.currentPageAnnotations = []

        // Reset Y position to top of page, but preserve horizontal margins (llx/urx)
        // This maintains list indentation and other horizontal context across page breaks
        base.layout.box.lly = base.layout.initial.lly
    }

    /// Ensure space for the given height, starting a new page if needed.
    ///
    /// - Returns: Whether a page break occurred.
    @discardableResult
    public mutating func ensure(height: PDF.UserSpace.Height) -> Bool {
        if exceeds(adding: height) {
            new()
            return true
        }
        return false
    }

    /// Check if adding the given height would exceed the page boundary.
    public func exceeds(adding height: PDF.UserSpace.Height) -> Bool {
        base.layout.box.lly + height > base.layout.maxY
    }

    /// Whether the current page has no rendered content.
    ///
    /// True when no content stream operations, no open text block, and no
    /// pending inline runs exist on the current page. Used to suppress
    /// redundant page breaks (e.g., `page-break-before: always` on the
    /// first element produces no blank page — matching browser behavior).
    public var isEmpty: Bool {
        base.currentPageBuilder.data.isEmpty
            && !base.text.blockOpen
            && base.inline.runs.isEmpty
    }
}
