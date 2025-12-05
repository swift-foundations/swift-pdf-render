// PDF.Context.Transform.swift
// Composable context transformations forming a monoid.

public import PDF_Standard

// MARK: - Context Transform

extension PDF.Context {
    /// A composable transformation on rendering context.
    ///
    /// `Transform` represents an endomorphism on `Context` (a function `Context → Context`).
    /// These transformations form a **monoid** under composition:
    ///
    /// ## Monoid Structure
    ///
    /// - **Identity**: `.identity` (does nothing)
    /// - **Composition**: `.then(_:)` (apply first, then second)
    /// - **Associativity**: `(a.then(b)).then(c) == a.then(b.then(c))`
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let transform = PDF.Context.Transform
    ///     .style(.with(font: .helveticaBold))
    ///     .then(.inset(.init(all: 10)))
    ///     .then(.translate(dy: 20))
    ///
    /// var context = PDF.Context(...)
    /// context = transform.apply(to: context)
    /// ```
    ///
    /// ## Scoped Application
    ///
    /// Use `scoped` to apply a transform temporarily:
    ///
    /// ```swift
    /// let result = transform.scoped { context in
    ///     // Context is transformed here
    ///     render(into: context)
    /// }
    /// // Original context state after scope
    /// ```
    public struct Transform: Sendable {
        /// The transformation function
        private let transform: @Sendable (PDF.Context) -> PDF.Context

        /// Create a transform from a function
        public init(_ transform: @escaping @Sendable (PDF.Context) -> PDF.Context) {
            self.transform = transform
        }

        /// Apply this transform to a context
        public func apply(to context: PDF.Context) -> PDF.Context {
            transform(context)
        }

        /// Apply this transform to a context in-place
        public func apply(to context: inout PDF.Context) {
            context = transform(context)
        }
    }
}

// MARK: - Monoid Identity

extension PDF.Context.Transform {
    /// The identity transform (does nothing).
    ///
    /// Satisfies:
    /// - `identity.then(f) == f`
    /// - `f.then(identity) == f`
    public static let identity = PDF.Context.Transform { $0 }
}

// MARK: - Monoid Composition

extension PDF.Context.Transform {
    /// Compose this transform with another (apply this first, then other).
    ///
    /// This is the monoid binary operation, satisfying associativity:
    /// `(a.then(b)).then(c) == a.then(b.then(c))`
    ///
    /// - Parameter other: The transform to apply after this one
    /// - Returns: A new transform that applies both in sequence
    public func then(_ other: PDF.Context.Transform) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            other.apply(to: self.apply(to: context))
        }
    }

    /// Compose multiple transforms left-to-right.
    ///
    /// - Parameter transforms: The transforms to compose
    /// - Returns: A single transform equivalent to applying all in order
    public static func composed(_ transforms: [PDF.Context.Transform]) -> PDF.Context.Transform {
        transforms.reduce(.identity) { $0.then($1) }
    }

    /// Compose multiple transforms left-to-right.
    public static func composed(_ transforms: PDF.Context.Transform...) -> PDF.Context.Transform {
        composed(transforms)
    }
}

// MARK: - Position Transforms

extension PDF.Context.Transform {
    /// Translate the current position.
    ///
    /// - Parameters:
    ///   - dx: Horizontal translation (default 0)
    ///   - dy: Vertical translation (default 0)
    /// - Returns: A transform that translates the position
    public static func translate(dx: PDF.UserSpace.Unit = 0, dy: PDF.UserSpace.Unit = 0) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox = ctx.layoutBox.translated(dx: dx, dy: dy)
            return ctx
        }
    }

    /// Translate using typed coordinates.
    public static func translate(dx: PDF.UserSpace.X? = nil, dy: PDF.UserSpace.Y? = nil) -> PDF.Context.Transform {
        translate(dx: .init(dx?.value ?? 0), dy: .init(dy?.value ?? 0))
    }

    /// Move to an absolute position.
    ///
    /// - Parameter position: The new position
    /// - Returns: A transform that sets the position
    public static func moveTo(_ position: PDF.UserSpace.Coordinate) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox.origin = position
            return ctx
        }
    }

    /// Move to absolute X position.
    public static func moveToX(_ x: PDF.UserSpace.X) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox.x = x
            return ctx
        }
    }

    /// Move to absolute Y position.
    public static func moveToY(_ y: PDF.UserSpace.Y) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox.y = y
            return ctx
        }
    }
}

// MARK: - Layout Transforms

extension PDF.Context.Transform {
    /// Apply insets to shrink the available layout box.
    ///
    /// - Parameter insets: The insets to apply
    /// - Returns: A transform that insets the layout box
    public static func inset(_ insets: PDF.UserSpace.EdgeInsets) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox = ctx.layoutBox.inset(by: insets)
            return ctx
        }
    }

    /// Apply uniform inset on all sides.
    public static func inset(_ amount: PDF.UserSpace.Unit) -> PDF.Context.Transform {
        inset(PDF.UserSpace.EdgeInsets(all: amount))
    }

    /// Constrain the width.
    ///
    /// - Parameter maxWidth: The maximum width
    /// - Returns: A transform that constrains width
    public static func constrainWidth(_ maxWidth: PDF.UserSpace.Width) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox = ctx.layoutBox.constrain.width(to: maxWidth)
            return ctx
        }
    }

    /// Constrain the height.
    ///
    /// - Parameter maxHeight: The maximum height
    /// - Returns: A transform that constrains height
    public static func constrainHeight(_ maxHeight: PDF.UserSpace.Height) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox = ctx.layoutBox.constrain.height(to: maxHeight)
            return ctx
        }
    }

    /// Set an explicit layout box.
    ///
    /// - Parameter box: The new layout box
    /// - Returns: A transform that sets the layout box
    public static func setLayoutBox(_ box: PDF.LayoutBox) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.layoutBox = box
            return ctx
        }
    }
}

// MARK: - Style Transforms

extension PDF.Context.Transform {
    /// Apply a partial style.
    ///
    /// The partial style is combined with the current style, with the
    /// new style's defined values taking precedence.
    ///
    /// - Parameter style: The partial style to apply
    /// - Returns: A transform that applies the style
    public static func style(_ style: PDF.Style) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            let currentAsPartial = PDF.Style(ctx.style)
            ctx.style = currentAsPartial.combined(with: style).resolved()
            return ctx
        }
    }

    /// Set the font.
    public static func font(_ font: PDF.Font) -> PDF.Context.Transform {
        style(.empty.with(font: font))
    }

    /// Set the font size.
    public static func fontSize(_ size: PDF.UserSpace.Unit) -> PDF.Context.Transform {
        style(.empty.with(fontSize: size))
    }

    /// Set the color.
    public static func color(_ color: PDF.Color) -> PDF.Context.Transform {
        style(.empty.with(color: color))
    }

    /// Set the line height multiplier.
    public static func lineHeight(_ multiplier: Double) -> PDF.Context.Transform {
        style(.empty.with(lineHeight: multiplier))
    }

    /// Set the text markup (underline, strikethrough).
    public static func textMarkup(_ markup: PDF.TextMarkup?) -> PDF.Context.Transform {
        style(.empty.with(textMarkup: markup))
    }
}

// MARK: - Graphics State Transforms

extension PDF.Context.Transform {
    /// Save the graphics state (push onto stack).
    ///
    /// Corresponds to PDF's `q` operator.
    public static let saveGraphicsState = PDF.Context.Transform { context in
        var ctx = context
        ctx.graphicsStack.save()
        return ctx
    }

    /// Restore the graphics state (pop from stack).
    ///
    /// Corresponds to PDF's `Q` operator.
    public static let restoreGraphicsState = PDF.Context.Transform { context in
        var ctx = context
        ctx.graphicsStack.restore()
        return ctx
    }

    /// Apply a CTM transformation.
    ///
    /// - Parameter transform: The affine transform to concatenate
    /// - Returns: A context transform that applies the affine transform
    public static func affineTransform(_ transform: PDF.UserSpace.AffineTransform) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            var ctx = context
            ctx.graphicsStack.concatenate(transform)
            return ctx
        }
    }
}

// MARK: - Scoped Execution

extension PDF.Context.Transform {
    /// Execute a closure with this transform applied, then restore.
    ///
    /// This is the **bracket pattern**: transform, execute, restore.
    ///
    /// ```swift
    /// let result = PDF.Context.Transform
    ///     .font(.helveticaBold)
    ///     .scoped(in: &context) { ctx in
    ///         // Font is bold here
    ///         render(into: &ctx)
    ///     }
    /// // Original font restored
    /// ```
    ///
    /// - Parameters:
    ///   - context: The context to transform
    ///   - body: The closure to execute with the transformed context
    /// - Returns: The result of the closure
    @discardableResult
    public func scoped<T>(
        in context: inout PDF.Context,
        _ body: (inout PDF.Context) throws -> T
    ) rethrows -> T {
        let original = context
        context = apply(to: context)
        defer { context = original }
        return try body(&context)
    }

    /// Execute a closure with this transform applied, returning result and new context.
    ///
    /// Unlike `scoped`, this does NOT restore the original context.
    ///
    /// - Parameters:
    ///   - context: The context to transform
    ///   - body: The closure to execute
    /// - Returns: The result of the closure
    @discardableResult
    public func applied<T>(
        to context: inout PDF.Context,
        _ body: (inout PDF.Context) throws -> T
    ) rethrows -> T {
        context = apply(to: context)
        return try body(&context)
    }
}

// MARK: - Conditional Transforms

extension PDF.Context.Transform {
    /// Create a conditional transform.
    ///
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - transform: The transform to apply if condition is true
    /// - Returns: A transform that conditionally applies
    public static func `if`(
        _ condition: @escaping @Sendable (PDF.Context) -> Bool,
        then transform: PDF.Context.Transform
    ) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            if condition(context) {
                return transform.apply(to: context)
            }
            return context
        }
    }

    /// Create a conditional transform with else branch.
    public static func `if`(
        _ condition: @escaping @Sendable (PDF.Context) -> Bool,
        then thenTransform: PDF.Context.Transform,
        else elseTransform: PDF.Context.Transform
    ) -> PDF.Context.Transform {
        PDF.Context.Transform { context in
            if condition(context) {
                return thenTransform.apply(to: context)
            } else {
                return elseTransform.apply(to: context)
            }
        }
    }
}

// MARK: - Operator Syntax

/// Forward composition operator for context transforms.
infix operator >>>: AdditionPrecedence

extension PDF.Context.Transform {
    /// Compose two transforms using the `>>>` operator.
    ///
    /// `a >>> b` is equivalent to `a.then(b)`.
    public static func >>> (lhs: PDF.Context.Transform, rhs: PDF.Context.Transform) -> PDF.Context.Transform {
        lhs.then(rhs)
    }
}
