// PDF.Spacer.swift

public import PDF_Standard

extension PDF {
    /// Fixed-size spacing element
    public struct Spacer: PDF.View, Sendable {
        /// Vertical space in points
        public var height: Double

        /// Create a spacer
        public init(_ height: Double) {
            self.height = height
        }

        public var body: Never {
            fatalError("PDF.Spacer is a leaf view")
        }

        public func render(context: inout PDF.Context) -> PDF.Content {
            context.advanceY(height)
            return PDF.Content()
        }
    }
}
