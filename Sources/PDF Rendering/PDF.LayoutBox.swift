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

    // MARK: - Namespace Accessors

    /// Access to split operations.
    ///
    /// Usage:
    /// ```swift
    /// let (top, bottom) = rect.split.vertically(at: 100)
    /// let (left, right) = rect.split.horizontally(at: 200)
    /// ```
    @inlinable
    public var split: Split { Split(self) }

    /// Access to constraining operations.
    ///
    /// Usage:
    /// ```swift
    /// let constrained = rect.constrain.width(to: 500)
    /// let constrained = rect.constrain.height(to: 300)
    /// ```
    @inlinable
    public var constrain: Constrain { Constrain(self) }

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
}

// MARK: - Split Namespace

extension PDF.UserSpace.Rectangle {
    /// Namespace for rectangle split operations.
    public struct Split: Sendable {
        @usableFromInline
        let rect: PDF.UserSpace.Rectangle

        @usableFromInline
        init(_ rect: PDF.UserSpace.Rectangle) {
            self.rect = rect
        }

        /// Split the box vertically, returning the top portion.
        ///
        /// - Parameter height: The height of the top portion
        /// - Returns: A tuple of (top box, remaining bottom box)
        @inlinable
        public func vertically(at height: PDF.UserSpace.Height) -> (top: PDF.UserSpace.Rectangle, bottom: PDF.UserSpace.Rectangle) {
            let splitHeight = Swift.min(height.value, rect.height.value)
            let top = PDF.UserSpace.Rectangle(
                x: rect.llx, y: rect.lly,
                width: rect.width,
                height: .init(splitHeight)
            )
            let bottom = PDF.UserSpace.Rectangle(
                x: rect.llx, y: .init(rect.lly.value + splitHeight),
                width: rect.width,
                height: .init(Swift.max(0, rect.height.value - splitHeight))
            )
            return (top, bottom)
        }

        /// Split the box horizontally, returning the left portion.
        ///
        /// - Parameter width: The width of the left portion
        /// - Returns: A tuple of (left box, remaining right box)
        @inlinable
        public func horizontally(at width: PDF.UserSpace.Width) -> (left: PDF.UserSpace.Rectangle, right: PDF.UserSpace.Rectangle) {
            let splitWidth = Swift.min(width.value, rect.width.value)
            let left = PDF.UserSpace.Rectangle(
                x: rect.llx, y: rect.lly,
                width: .init(splitWidth),
                height: rect.height
            )
            let right = PDF.UserSpace.Rectangle(
                x: .init(rect.llx.value + splitWidth), y: rect.lly,
                width: .init(Swift.max(0, rect.width.value - splitWidth)),
                height: rect.height
            )
            return (left, right)
        }
    }
}

// MARK: - Constrain Namespace

extension PDF.UserSpace.Rectangle {
    /// Namespace for rectangle constraining operations.
    public struct Constrain: Sendable {
        @usableFromInline
        let rect: PDF.UserSpace.Rectangle

        @usableFromInline
        init(_ rect: PDF.UserSpace.Rectangle) {
            self.rect = rect
        }

        /// Constrain the width to a maximum value.
        ///
        /// - Parameter maxWidth: The maximum width
        /// - Returns: A new box with constrained width
        @inlinable
        public func width(to maxWidth: PDF.UserSpace.Width) -> PDF.UserSpace.Rectangle {
            var copy = rect
            copy.width = .init(Swift.min(rect.width.value, maxWidth.value))
            return copy
        }

        /// Constrain the height to a maximum value.
        ///
        /// - Parameter maxHeight: The maximum height
        /// - Returns: A new box with constrained height
        @inlinable
        public func height(to maxHeight: PDF.UserSpace.Height) -> PDF.UserSpace.Rectangle {
            var copy = rect
            copy.height = .init(Swift.min(rect.height.value, maxHeight.value))
            return copy
        }
    }
}

