// PDF.LayoutBox.swift
// Layout constraints as a bounded region with lattice structure.

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
    public struct LayoutBox: Sendable, Equatable {
        /// The origin point (top-left corner in rendering coordinates)
        public var origin: PDF.UserSpace.Coordinate

        /// The available size (width × height)
        public var size: PDF.UserSpace.Size

        // MARK: - Initializers

        /// Create a layout box from origin and size
        public init(origin: PDF.UserSpace.Coordinate, size: PDF.UserSpace.Size) {
            self.origin = origin
            self.size = size
        }

        /// Create a layout box from components
        public init(
            x: PDF.UserSpace.X,
            y: PDF.UserSpace.Y,
            width: PDF.UserSpace.Width,
            height: PDF.UserSpace.Height
        ) {
            self.origin = PDF.UserSpace.Coordinate(x: x, y: y)
            self.size = PDF.UserSpace.Size(width: width, height: height)
        }

        /// Create a layout box from a rectangle
        public init(_ rectangle: PDF.UserSpace.Rectangle) {
            self.origin = rectangle.origin
            self.size = rectangle.size
        }
    }
}

// MARK: - Computed Properties

extension PDF.LayoutBox {
    /// X coordinate of the origin
    @inlinable
    public var x: PDF.UserSpace.X {
        get { origin.x }
        set { origin.x = newValue }
    }

    /// Y coordinate of the origin
    @inlinable
    public var y: PDF.UserSpace.Y {
        get { origin.y }
        set { origin.y = newValue }
    }

    /// Available width
    @inlinable
    public var width: PDF.UserSpace.Width {
        get { size.width }
        set { size.width = newValue }
    }

    /// Available height
    @inlinable
    public var height: PDF.UserSpace.Height {
        get { size.height }
        set { size.height = newValue }
    }

    /// The maximum X coordinate (right edge)
    @inlinable
    public var maxX: PDF.UserSpace.X {
        PDF.UserSpace.X(x.value + width.value)
    }

    /// The maximum Y coordinate (bottom edge)
    @inlinable
    public var maxY: PDF.UserSpace.Y {
        PDF.UserSpace.Y(y.value + height.value)
    }

    /// Convert to a rectangle
    @inlinable
    public var rectangle: PDF.UserSpace.Rectangle {
        PDF.UserSpace.Rectangle(origin: origin, size: size)
    }
}

// MARK: - Lattice Identity Elements

extension PDF.LayoutBox {
    /// The empty box (lattice bottom ⊥).
    ///
    /// Has zero size and represents no available space.
    public static let empty = PDF.LayoutBox(
        origin: .zero,
        size: .zero
    )

    /// Check if this box is empty (has no area)
    @inlinable
    public var isEmpty: Bool {
        width.value <= 0 || height.value <= 0
    }
}

// MARK: - Lattice Operations

extension PDF.LayoutBox {
    /// Intersection of two layout boxes (lattice meet ∧).
    ///
    /// Returns the largest box contained in both boxes.
    /// If the boxes don't overlap, returns an empty box.
    ///
    /// - Parameter other: The box to intersect with
    /// - Returns: The intersection, or `.empty` if disjoint
    public func intersection(_ other: PDF.LayoutBox) -> PDF.LayoutBox {
        let newMinX = max(x.value, other.x.value)
        let newMinY = max(y.value, other.y.value)
        let newMaxX = min(maxX.value, other.maxX.value)
        let newMaxY = min(maxY.value, other.maxY.value)

        let newWidth = newMaxX - newMinX
        let newHeight = newMaxY - newMinY

        guard newWidth > 0, newHeight > 0 else {
            return .empty
        }

        return PDF.LayoutBox(
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
    public func union(_ other: PDF.LayoutBox) -> PDF.LayoutBox {
        guard !isEmpty else { return other }
        guard !other.isEmpty else { return self }

        let newMinX = min(x.value, other.x.value)
        let newMinY = min(y.value, other.y.value)
        let newMaxX = max(maxX.value, other.maxX.value)
        let newMaxY = max(maxY.value, other.maxY.value)

        return PDF.LayoutBox(
            x: .init(newMinX),
            y: .init(newMinY),
            width: .init(newMaxX - newMinX),
            height: .init(newMaxY - newMinY)
        )
    }
}

// MARK: - Transformations (Endomorphisms)

extension PDF.LayoutBox {
    /// Apply insets to shrink the box.
    ///
    /// - Parameter insets: The insets to apply
    /// - Returns: A new box with the insets applied
    public func inset(by insets: PDF.UserSpace.EdgeInsets) -> PDF.LayoutBox {
        PDF.LayoutBox(
            x: .init(x.value + insets.leading),
            y: .init(y.value + insets.top),
            width: .init(max(0, width.value - insets.horizontal)),
            height: .init(max(0, height.value - insets.vertical))
        )
    }

    /// Apply uniform inset on all sides.
    ///
    /// - Parameter amount: The inset amount
    /// - Returns: A new box with uniform insets
    public func inset(_ amount: PDF.UserSpace.Unit) -> PDF.LayoutBox {
        inset(by: PDF.UserSpace.EdgeInsets(all: amount))
    }

    /// Translate the box origin.
    ///
    /// - Parameters:
    ///   - dx: Horizontal translation
    ///   - dy: Vertical translation
    /// - Returns: A new box with translated origin
    public func translated(dx: PDF.UserSpace.Unit = 0, dy: PDF.UserSpace.Unit = 0) -> PDF.LayoutBox {
        PDF.LayoutBox(
            x: .init(x.value + dx),
            y: .init(y.value + dy),
            width: width,
            height: height
        )
    }

    /// Translate the box origin by a vector.
    ///
    /// - Parameter vector: The translation vector
    /// - Returns: A new box with translated origin
    public func translated(by vector: PDF.UserSpace.Vector) -> PDF.LayoutBox {
        translated(dx: .init(vector.dx.value), dy: .init(vector.dy.value))
    }

    /// Constrain the width to a maximum value.
    ///
    /// - Parameter maxWidth: The maximum width
    /// - Returns: A new box with constrained width
    public func constrainingWidth(to maxWidth: PDF.UserSpace.Width) -> PDF.LayoutBox {
        var copy = self
        copy.width = .init(min(width.value, maxWidth.value))
        return copy
    }

    /// Constrain the height to a maximum value.
    ///
    /// - Parameter maxHeight: The maximum height
    /// - Returns: A new box with constrained height
    public func constrainingHeight(to maxHeight: PDF.UserSpace.Height) -> PDF.LayoutBox {
        var copy = self
        copy.height = .init(min(height.value, maxHeight.value))
        return copy
    }

    /// Set the width explicitly.
    ///
    /// - Parameter newWidth: The new width
    /// - Returns: A new box with the specified width
    public func with(width newWidth: PDF.UserSpace.Width) -> PDF.LayoutBox {
        var copy = self
        copy.width = newWidth
        return copy
    }

    /// Set the height explicitly.
    ///
    /// - Parameter newHeight: The new height
    /// - Returns: A new box with the specified height
    public func with(height newHeight: PDF.UserSpace.Height) -> PDF.LayoutBox {
        var copy = self
        copy.height = newHeight
        return copy
    }
}

// MARK: - Subdivision

extension PDF.LayoutBox {
    /// Split the box horizontally, returning the top portion.
    ///
    /// - Parameter height: The height of the top portion
    /// - Returns: A tuple of (top box, remaining bottom box)
    public func splitVertically(at height: PDF.UserSpace.Height) -> (top: PDF.LayoutBox, bottom: PDF.LayoutBox) {
        let splitHeight = min(height.value, self.height.value)
        let top = PDF.LayoutBox(
            x: x, y: y,
            width: width,
            height: .init(splitHeight)
        )
        let bottom = PDF.LayoutBox(
            x: x, y: .init(y.value + splitHeight),
            width: width,
            height: .init(max(0, self.height.value - splitHeight))
        )
        return (top, bottom)
    }

    /// Split the box vertically, returning the left portion.
    ///
    /// - Parameter width: The width of the left portion
    /// - Returns: A tuple of (left box, remaining right box)
    public func splitHorizontally(at width: PDF.UserSpace.Width) -> (left: PDF.LayoutBox, right: PDF.LayoutBox) {
        let splitWidth = min(width.value, self.width.value)
        let left = PDF.LayoutBox(
            x: x, y: y,
            width: .init(splitWidth),
            height: height
        )
        let right = PDF.LayoutBox(
            x: .init(x.value + splitWidth), y: y,
            width: .init(max(0, self.width.value - splitWidth)),
            height: height
        )
        return (left, right)
    }
}

// MARK: - Containment

extension PDF.LayoutBox {
    /// Check if a point is within this box.
    ///
    /// - Parameter point: The point to check
    /// - Returns: True if the point is inside the box
    public func contains(_ point: PDF.UserSpace.Coordinate) -> Bool {
        point.x.value >= x.value &&
        point.x.value <= maxX.value &&
        point.y.value >= y.value &&
        point.y.value <= maxY.value
    }

    /// Check if this box fully contains another box.
    ///
    /// - Parameter other: The box to check
    /// - Returns: True if `other` is fully inside this box
    public func contains(_ other: PDF.LayoutBox) -> Bool {
        other.x.value >= x.value &&
        other.y.value >= y.value &&
        other.maxX.value <= maxX.value &&
        other.maxY.value <= maxY.value
    }
}
