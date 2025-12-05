// PDF.LayoutBox.swift
// Layout constraints as a bounded region - typealias to UserSpace.Rectangle.

public import PDF_Standard

extension PDF {
    /// A bounded region for layout, representing available space.
    ///
    /// `LayoutBox` describes the rectangular area available for content placement.
    /// It tracks both the origin (where content starts) and the available size
    /// (how much space remains).
    ///
    /// ## Category-Theoretic Structure
    ///
    /// `LayoutBox` forms a **bounded lattice** under intersection:
    /// - **Meet (∧)**: Intersection of two boxes
    /// - **Join (∨)**: Bounding box containing both
    /// - **Top (⊤)**: Infinite box (unbounded)
    /// - **Bottom (⊥)**: Empty box (zero size)
    ///
    /// ## Coordinate System
    ///
    /// Uses top-left origin with Y increasing downward (matching HTML/CSS),
    /// which is transformed to PDF's bottom-left origin during page creation.
    ///
    /// ```
    /// origin (x, y)
    ///    ┌──────────────────┐
    ///    │                  │ height
    ///    │   content area   │
    ///    │                  │
    ///    └──────────────────┘
    ///           width
    /// ```
    public typealias LayoutBox = PDF.UserSpace.Rectangle
}

// MARK: - Layout-Specific Extensions

extension PDF.UserSpace.Rectangle {

    // MARK: - Computed Properties (Convenience Aliases)

    /// X coordinate of the origin (alias for llx)
    @inlinable
    public var x: PDF.UserSpace.X {
        get { llx }
        set { origin = PDF.UserSpace.Coordinate(x: newValue, y: lly) }
    }

    /// Y coordinate of the origin (alias for lly)
    @inlinable
    public var y: PDF.UserSpace.Y {
        get { lly }
        set { origin = PDF.UserSpace.Coordinate(x: llx, y: newValue) }
    }

    /// Convert to a rectangle (identity for layout box)
    @inlinable
    public var rectangle: PDF.UserSpace.Rectangle { self }

    // MARK: - Lattice Identity Elements

    /// The empty box (lattice bottom ⊥).
    ///
    /// Has zero size and represents no available space.
    public static let empty = PDF.UserSpace.Rectangle(
        origin: .zero,
        size: .zero
    )

    // MARK: - Transformations (Endomorphisms)

    /// Apply insets to shrink the box (layout-specific with top/leading semantics).
    ///
    /// - Parameter insets: The insets to apply
    /// - Returns: A new box with the insets applied
    public func inset(by insets: PDF.UserSpace.EdgeInsets) -> PDF.UserSpace.Rectangle {
        PDF.UserSpace.Rectangle(
            x: .init(llx.value + insets.leading),
            y: .init(lly.value + insets.top),
            width: .init(Swift.max(0, width.value - insets.horizontal)),
            height: .init(Swift.max(0, height.value - insets.vertical))
        )
    }

    /// Apply uniform inset on all sides.
    ///
    /// - Parameter amount: The inset amount
    /// - Returns: A new box with uniform insets
    public func inset(_ amount: PDF.UserSpace.Unit) -> PDF.UserSpace.Rectangle {
        inset(by: PDF.UserSpace.EdgeInsets(all: amount))
    }

    /// Constrain the width to a maximum value.
    ///
    /// - Parameter maxWidth: The maximum width
    /// - Returns: A new box with constrained width
    public func constrainingWidth(to maxWidth: PDF.UserSpace.Width) -> PDF.UserSpace.Rectangle {
        var copy = self
        copy.width = .init(Swift.min(width.value, maxWidth.value))
        return copy
    }

    /// Constrain the height to a maximum value.
    ///
    /// - Parameter maxHeight: The maximum height
    /// - Returns: A new box with constrained height
    public func constrainingHeight(to maxHeight: PDF.UserSpace.Height) -> PDF.UserSpace.Rectangle {
        var copy = self
        copy.height = .init(Swift.min(height.value, maxHeight.value))
        return copy
    }

    /// Set the width explicitly.
    ///
    /// - Parameter newWidth: The new width
    /// - Returns: A new box with the specified width
    public func with(width newWidth: PDF.UserSpace.Width) -> PDF.UserSpace.Rectangle {
        var copy = self
        copy.width = newWidth
        return copy
    }

    /// Set the height explicitly.
    ///
    /// - Parameter newHeight: The new height
    /// - Returns: A new box with the specified height
    public func with(height newHeight: PDF.UserSpace.Height) -> PDF.UserSpace.Rectangle {
        var copy = self
        copy.height = newHeight
        return copy
    }

    // MARK: - Subdivision

    /// Split the box horizontally, returning the top portion.
    ///
    /// - Parameter height: The height of the top portion
    /// - Returns: A tuple of (top box, remaining bottom box)
    public func splitVertically(at height: PDF.UserSpace.Height) -> (top: PDF.UserSpace.Rectangle, bottom: PDF.UserSpace.Rectangle) {
        let splitHeight = Swift.min(height.value, self.height.value)
        let top = PDF.UserSpace.Rectangle(
            x: llx, y: lly,
            width: width,
            height: .init(splitHeight)
        )
        let bottom = PDF.UserSpace.Rectangle(
            x: llx, y: .init(lly.value + splitHeight),
            width: width,
            height: .init(Swift.max(0, self.height.value - splitHeight))
        )
        return (top, bottom)
    }

    /// Split the box vertically, returning the left portion.
    ///
    /// - Parameter width: The width of the left portion
    /// - Returns: A tuple of (left box, remaining right box)
    public func splitHorizontally(at width: PDF.UserSpace.Width) -> (left: PDF.UserSpace.Rectangle, right: PDF.UserSpace.Rectangle) {
        let splitWidth = Swift.min(width.value, self.width.value)
        let left = PDF.UserSpace.Rectangle(
            x: llx, y: lly,
            width: .init(splitWidth),
            height: height
        )
        let right = PDF.UserSpace.Rectangle(
            x: .init(llx.value + splitWidth), y: lly,
            width: .init(Swift.max(0, self.width.value - splitWidth)),
            height: height
        )
        return (left, right)
    }

    // MARK: - Lattice Operations

    /// Intersection of two layout boxes (lattice meet ∧).
    ///
    /// Returns the largest box contained in both boxes.
    /// If the boxes don't overlap, returns an empty box.
    ///
    /// - Parameter other: The box to intersect with
    /// - Returns: The intersection, or `.empty` if disjoint
    public func layoutIntersection(_ other: PDF.UserSpace.Rectangle) -> PDF.UserSpace.Rectangle {
        let newMinX = Swift.max(llx.value, other.llx.value)
        let newMinY = Swift.max(lly.value, other.lly.value)
        let newMaxX = Swift.min(maxX.value, other.maxX.value)
        let newMaxY = Swift.min(maxY.value, other.maxY.value)

        let newWidth = newMaxX - newMinX
        let newHeight = newMaxY - newMinY

        guard newWidth > 0, newHeight > 0 else {
            return .empty
        }

        return PDF.UserSpace.Rectangle(
            x: .init(newMinX),
            y: .init(newMinY),
            width: .init(newWidth),
            height: .init(newHeight)
        )
    }

    /// Union bounding box (lattice join ∨).
    ///
    /// Returns the smallest box containing both boxes.
    ///
    /// - Parameter other: The box to union with
    /// - Returns: The bounding box containing both
    public func layoutUnion(_ other: PDF.UserSpace.Rectangle) -> PDF.UserSpace.Rectangle {
        guard !isEmpty else { return other }
        guard !other.isEmpty else { return self }

        let newMinX = Swift.min(llx.value, other.llx.value)
        let newMinY = Swift.min(lly.value, other.lly.value)
        let newMaxX = Swift.max(maxX.value, other.maxX.value)
        let newMaxY = Swift.max(maxY.value, other.maxY.value)

        return PDF.UserSpace.Rectangle(
            x: .init(newMinX),
            y: .init(newMinY),
            width: .init(newMaxX - newMinX),
            height: .init(newMaxY - newMinY)
        )
    }
}
