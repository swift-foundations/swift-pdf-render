// PDF.Spacer.swift

public import PDF_Standard

extension PDF {
    /// Fixed-size spacing element
    public struct Spacer: PDF.View, Sendable {
        public typealias Content = Never

        /// Vertical space in points
        public var height: Double

        /// Create a spacer
        public init(_ height: Double) {
            self.height = height
        }

        public var body: Never {
            fatalError("PDF.Spacer is a leaf view")
        }

        public static func _render(
            _ view: Self,
            context: inout PDF.Context
        ) -> PDF.Content {
            context.advanceY(view.height)
            return PDF.Content()
        }
    }
}
