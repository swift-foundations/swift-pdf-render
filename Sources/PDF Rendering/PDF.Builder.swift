// PDF.Builder.swift

public import PDF_Standard

extension PDF {
    /// Result builder for composing PDF views
    @resultBuilder
    public struct Builder {
        public static func buildExpression<V: PDF.View>(_ expression: V) -> [any PDF.View] {
            [expression]
        }

        public static func buildBlock(_ components: [any PDF.View]...) -> [any PDF.View] {
            components.flatMap { $0 }
        }

        public static func buildOptional(_ component: [any PDF.View]?) -> [any PDF.View] {
            component ?? []
        }

        public static func buildEither(first component: [any PDF.View]) -> [any PDF.View] {
            component
        }

        public static func buildEither(second component: [any PDF.View]) -> [any PDF.View] {
            component
        }

        public static func buildArray(_ components: [[any PDF.View]]) -> [any PDF.View] {
            components.flatMap { $0 }
        }
    }
}
