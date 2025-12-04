// PDF.Spacer.swift

public import PDF_Standard
public import Renderable

extension PDF {
    /// Fixed-size spacing element
    public struct Spacer: PDF.View, Sendable {
        public typealias Content = Never
        public typealias Context = PDF.Context
        public typealias Output = PDF.Render.Operation

        /// Vertical space in points
        public var height: Double

        /// Create a spacer
        public init(_ height: Double) {
            self.height = height
        }

        public var body: Never {
            fatalError("PDF.Spacer is a leaf view")
        }

        public static func _render<Buffer: RangeReplaceableCollection>(
            _ view: Self,
            into buffer: inout Buffer,
            context: inout PDF.Context
        ) where Buffer.Element == PDF.Render.Operation {
            context.advanceY(PDF.UserSpace.Y(PDF.UserSpace.Unit(view.height)))
            // Spacer produces no operations, just advances position
        }
    }
}
