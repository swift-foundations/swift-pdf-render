// PDF.Page.Builder.swift

extension PDF.Page {
    /// Result builder for document pages
    @resultBuilder
    public struct Builder {
        public static func buildBlock(_ components: [PDF.Page]...) -> [PDF.Page] {
            components.flatMap { $0 }
        }

        public static func buildOptional(_ component: [PDF.Page]?) -> [PDF.Page] {
            component ?? []
        }

        public static func buildEither(first component: [PDF.Page]) -> [PDF.Page] {
            component
        }

        public static func buildEither(second component: [PDF.Page]) -> [PDF.Page] {
            component
        }

        public static func buildArray(_ components: [[PDF.Page]]) -> [PDF.Page] {
            components.flatMap { $0 }
        }

        public static func buildExpression(_ page: PDF.Page) -> [PDF.Page] {
            [page]
        }
    }
}
