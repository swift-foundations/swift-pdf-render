//
//  PDF.Context.List.Marker.swift
//  swift-pdf-rendering
//

public import Byte_Primitives
public import Geometry_Primitives
public import PDF_Standard

// MARK: - List Marker

extension PDF.Context.List {
    /// A list marker that can be either text-based or graphic.
    ///
    /// Text markers (bullet, numbers) use font glyphs.
    /// Graphic markers (circle for Level 2) are drawn using PDF path operators.
    public enum Marker: Sendable {
        /// Text-based marker (bullet, number, square)
        case text(bytes: [Byte], font: PDF.Font)

        /// Stroked circle marker (hollow circle for Level 2)
        case strokedCircle(
            PDF.UserSpace.Circle,
            strokeWidth: PDF.UserSpace.Width
        )

        /// Filled disc marker (solid circle for Level 1)
        case filledCircle(PDF.UserSpace.Circle)

        /// Filled square marker (for Level 3+)
        case filledSquare(PDF.UserSpace.Rectangle)
    }
}
