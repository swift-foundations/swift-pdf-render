// PDF.Render.Result.swift
// Render result accumulator (Writer monoid).

public import PDF_Standard

extension PDF.Render {
    /// The result of rendering, forming a **Writer monoid**.
    ///
    /// `Result` accumulates rendering output (operations, annotations)
    /// along with metadata about the rendering (consumed height).
    ///
    /// ## Monoid Structure
    ///
    /// - **Identity**: `.empty` (no operations, zero height)
    /// - **Composition**: `.appending(_:)` (concatenate operations)
    /// - **Associativity**: `(a.appending(b)).appending(c) == a.appending(b.appending(c))`
    ///
    /// ## Writer Monad Pattern
    ///
    /// The render process can be viewed as a Writer monad:
    /// - **W (Monoid)**: `Result`
    /// - **tell**: Add operations without a meaningful return value
    /// - **listen**: Observe the accumulated operations
    /// - **pass**: Transform the accumulated operations
    public struct Result: Sendable, Equatable {
        /// The accumulated rendering operations
        public var operations: [Operation]

        /// Annotations generated during rendering
        public var annotations: [PDF.Annotation]

        /// The vertical height consumed during rendering
        public var consumedHeight: PDF.UserSpace.Height

        // MARK: - Initializers

        /// Create a render result
        public init(
            operations: [Operation] = [],
            annotations: [PDF.Annotation] = [],
            consumedHeight: PDF.UserSpace.Height = .zero
        ) {
            self.operations = operations
            self.annotations = annotations
            self.consumedHeight = consumedHeight
        }

        /// Create a render result from a single operation
        public init(operation: Operation, consumedHeight: PDF.UserSpace.Height = .zero) {
            self.operations = [operation]
            self.annotations = []
            self.consumedHeight = consumedHeight
        }

        /// Create a render result from a single text operation
        public init(text: Operation.Text, consumedHeight: PDF.UserSpace.Height = .zero) {
            self.init(operation: .text(text), consumedHeight: consumedHeight)
        }

        /// Create a render result from a single graphics operation
        public init(graphics: Operation.Graphics, consumedHeight: PDF.UserSpace.Height = .zero) {
            self.init(operation: .graphics(graphics), consumedHeight: consumedHeight)
        }
    }
}

// MARK: - Result Monoid Identity

extension PDF.Render.Result {
    /// The empty render result (monoid identity).
    ///
    /// Satisfies:
    /// - `empty.appending(r) == r`
    /// - `r.appending(empty) == r`
    public static let empty = PDF.Render.Result()
}

// MARK: - Result Monoid Operation

extension PDF.Render.Result {
    /// Append another render result (monoid binary operation).
    ///
    /// Operations and annotations are concatenated.
    /// Heights are summed.
    ///
    /// - Parameter other: The result to append
    /// - Returns: A new result containing both
    public func appending(_ other: PDF.Render.Result) -> PDF.Render.Result {
        PDF.Render.Result(
            operations: operations + other.operations,
            annotations: annotations + other.annotations,
            consumedHeight: .init(consumedHeight.value + other.consumedHeight.value)
        )
    }

    /// Append a single operation.
    public func appending(
        _ operation: PDF.Render.Operation,
        consumedHeight height: PDF.UserSpace.Height = .zero
    ) -> PDF.Render.Result {
        PDF.Render.Result(
            operations: operations + [operation],
            annotations: annotations,
            consumedHeight: .init(consumedHeight.value + height.value)
        )
    }

    /// Append a text operation.
    public func appending(
        text: PDF.Render.Operation.Text,
        consumedHeight height: PDF.UserSpace.Height = .zero
    ) -> PDF.Render.Result {
        appending(.text(text), consumedHeight: height)
    }

    /// Append a graphics operation.
    public func appending(
        graphics: PDF.Render.Operation.Graphics,
        consumedHeight height: PDF.UserSpace.Height = .zero
    ) -> PDF.Render.Result {
        appending(.graphics(graphics), consumedHeight: height)
    }

    /// Append an annotation.
    public func appending(annotation: PDF.Annotation) -> PDF.Render.Result {
        PDF.Render.Result(
            operations: operations,
            annotations: annotations + [annotation],
            consumedHeight: consumedHeight
        )
    }

    /// Combine multiple results (fold).
    public static func combined(_ results: [PDF.Render.Result]) -> PDF.Render.Result {
        results.reduce(.empty) { $0.appending($1) }
    }

    /// Combine multiple results.
    public static func combined(_ results: PDF.Render.Result...) -> PDF.Render.Result {
        combined(results)
    }
}

// MARK: - Result Mutating Helpers

extension PDF.Render.Result {
    /// Append an operation in place.
    public mutating func append(_ operation: PDF.Render.Operation) {
        operations.append(operation)
    }

    /// Append multiple operations in place.
    public mutating func append(contentsOf newOperations: [PDF.Render.Operation]) {
        operations.append(contentsOf: newOperations)
    }

    /// Append an annotation in place.
    public mutating func append(annotation: PDF.Annotation) {
        annotations.append(annotation)
    }

    /// Add to consumed height in place.
    public mutating func advance(by amount: PDF.UserSpace.Height) {
        consumedHeight = .init(consumedHeight.value + amount.value)
    }
}

// MARK: - Result Writer Operations

extension PDF.Render.Result {
    /// Create a result that just logs an operation (Writer's `tell`).
    public static func tell(_ operation: PDF.Render.Operation) -> PDF.Render.Result {
        PDF.Render.Result(operation: operation)
    }

    /// Create a result that logs multiple operations.
    public static func tell(_ operations: [PDF.Render.Operation]) -> PDF.Render.Result {
        PDF.Render.Result(operations: operations)
    }

    /// Map over the operations (Writer's `pass` simplified).
    public func mapOperations(
        _ transform: ([PDF.Render.Operation]) -> [PDF.Render.Operation]
    ) -> PDF.Render.Result {
        PDF.Render.Result(
            operations: transform(operations),
            annotations: annotations,
            consumedHeight: consumedHeight
        )
    }
}

// MARK: - Result Convenience Factories

extension PDF.Render.Result {
    /// Create a result for a text string at a position.
    public static func text(
        _ string: String,
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Unit,
        color: PDF.Color,
        consumedHeight: PDF.UserSpace.Height = .zero
    ) -> PDF.Render.Result {
        PDF.Render.Result(
            text: PDF.Render.Operation.Text(
                text: string,
                position: position,
                font: font,
                size: size,
                color: color
            ),
            consumedHeight: consumedHeight
        )
    }

    /// Create a result for a line.
    public static func line(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width
    ) -> PDF.Render.Result {
        PDF.Render.Result(
            graphics: .line(from: from, to: to, color: color, width: width)
        )
    }

    /// Create a result for a rectangle.
    public static func rectangle(
        _ rect: PDF.UserSpace.Rectangle,
        fill: PDF.Color? = nil,
        stroke: PDF.Color? = nil,
        strokeWidth: PDF.UserSpace.Width = .init(1)
    ) -> PDF.Render.Result {
        PDF.Render.Result(
            graphics: .rectangle(rect, fill: fill, stroke: stroke, strokeWidth: strokeWidth)
        )
    }
}

// MARK: - Result Operator Syntax

/// Semigroup/monoid composition operator for render results.
infix operator <>: AdditionPrecedence

extension PDF.Render.Result {
    /// Combine two results using the `<>` operator (semigroup/monoid).
    public static func <> (lhs: PDF.Render.Result, rhs: PDF.Render.Result) -> PDF.Render.Result {
        lhs.appending(rhs)
    }
}
