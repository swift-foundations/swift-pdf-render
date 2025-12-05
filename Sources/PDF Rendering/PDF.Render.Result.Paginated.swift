// PDF.Render.Result.Paginated.swift
// Paginated render result container.

public import PDF_Standard

extension PDF.Render.Result {
    /// A paginated render result with multiple pages.
    public struct Paginated: Sendable, Equatable {
        /// Operations grouped by page
        public var pages: [[PDF.Render.Operation]]

        /// Annotations grouped by page
        public var pageAnnotations: [[PDF.Annotation]]

        /// Create a paginated result
        public init(
            pages: [[PDF.Render.Operation]] = [],
            pageAnnotations: [[PDF.Annotation]] = []
        ) {
            self.pages = pages
            self.pageAnnotations = pageAnnotations
        }

        /// The number of pages
        public var pageCount: Int {
            pages.count
        }

        /// Whether there are any pages
        public var isEmpty: Bool {
            pages.isEmpty || pages.allSatisfy { $0.isEmpty }
        }
    }
}
