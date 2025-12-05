// PDF.GraphicsState.swift
// Graphics state for PDF rendering - direct use of ISO 32000 types.
//
// This file provides convenience extensions for working with
// ISO_32000.GraphicsState in rendering contexts.
//
// There are no typealiases here - use the full ISO 32000 type paths directly:
// - ISO_32000.GraphicsState (device-independent graphics state)
// - ISO_32000.Graphics.State.Stack<ISO_32000.GraphicsState> (state stack)

public import PDF_Standard
import Foundation

// MARK: - Transformation Helpers

extension ISO_32000.Graphics.State.Stack where State == ISO_32000.GraphicsState {
    /// Apply a transformation to the current CTM.
    ///
    /// This composes the given transform with the current CTM.
    ///
    /// - Parameter transform: The transform to concatenate
    public mutating func concatenate(_ transform: ISO_32000.AffineTransform<ISO_32000.UserSpace.Unit>) {
        current.ctm = current.ctm.concatenating(transform)
    }

    /// Translate the current coordinate system.
    ///
    /// - Parameters:
    ///   - x: Horizontal translation in user space units
    ///   - y: Vertical translation in user space units
    public mutating func translate(x: ISO_32000.UserSpace.Unit, y: ISO_32000.UserSpace.Unit) {
        concatenate(.translation(x: x, y: y))
    }

    /// Scale the current coordinate system.
    ///
    /// - Parameters:
    ///   - x: Horizontal scale factor
    ///   - y: Vertical scale factor
    public mutating func scale(x: ISO_32000.UserSpace.Unit, y: ISO_32000.UserSpace.Unit) {
        concatenate(.scale(x: x, y: y))
    }

    /// Rotate the current coordinate system.
    ///
    /// - Parameter angle: Rotation angle in radians
    public mutating func rotate(_ angle: Radian) {
        let c = ISO_32000.UserSpace.Unit(cos(angle.value))
        let s = ISO_32000.UserSpace.Unit(sin(angle.value))
        let rotation = ISO_32000.AffineTransform<ISO_32000.UserSpace.Unit>(
            a: c, b: s, c: -s, d: c,
            tx: .init(0), ty: .init(0)
        )
        concatenate(rotation)
    }
}

// MARK: - Text State Helpers

extension ISO_32000.Graphics.State.Stack where State == ISO_32000.GraphicsState {
    /// Set the font size on the current state.
    public mutating func setFontSize(_ size: ISO_32000.UserSpace.Unit) {
        current.textState.fontSize = size
    }

    /// Set the leading (line spacing) on the current state.
    ///
    /// Leading is the vertical distance between baselines of adjacent lines.
    /// Typical value: 1.2 × fontSize for comfortable reading.
    public mutating func setLeading(_ leading: ISO_32000.UserSpace.Unit) {
        current.textState.leading = leading
    }

    /// Set the text rise (baseline offset) on the current state.
    ///
    /// Positive values move the baseline up (superscript).
    /// Negative values move the baseline down (subscript).
    public mutating func setRise(_ rise: ISO_32000.UserSpace.Unit) {
        current.textState.rise = rise
    }

    /// Set the character spacing on the current state.
    public mutating func setCharacterSpacing(_ spacing: ISO_32000.UserSpace.Unit) {
        current.textState.characterSpacing = spacing
    }

    /// Set the word spacing on the current state.
    public mutating func setWordSpacing(_ spacing: ISO_32000.UserSpace.Unit) {
        current.textState.wordSpacing = spacing
    }
}

// MARK: - Color Helpers

extension ISO_32000.Graphics.State.Stack where State == ISO_32000.GraphicsState {
    /// Set the nonstroking (fill) color on the current state.
    public mutating func setFillColor(_ color: ISO_32000.`8`.`4`.Graphics.State.Color) {
        current.nonstrokingColor = color
    }

    /// Set the stroking (stroke) color on the current state.
    public mutating func setStrokeColor(_ color: ISO_32000.`8`.`4`.Graphics.State.Color) {
        current.strokingColor = color
    }
}

// MARK: - Line Style Helpers

extension ISO_32000.Graphics.State.Stack where State == ISO_32000.GraphicsState {
    /// Set the line width on the current state.
    public mutating func setLineWidth(_ width: ISO_32000.UserSpace.Unit) {
        current.lineWidth = width
    }

    /// Set the line cap style on the current state.
    public mutating func setLineCap(_ cap: ISO_32000.`8`.`4`.Graphics.State.Line.Cap) {
        current.lineCap = cap
    }

    /// Set the line join style on the current state.
    public mutating func setLineJoin(_ join: ISO_32000.`8`.`4`.Graphics.State.Line.Join) {
        current.lineJoin = join
    }

    /// Set the dash pattern on the current state.
    public mutating func setDashPattern(_ pattern: ISO_32000.`8`.`4`.Graphics.State.Line.Dash.Pattern) {
        current.dashPattern = pattern
    }
}

// MARK: - Comonad-like Operations

extension ISO_32000.Graphics.State.Stack where State == ISO_32000.GraphicsState {
    /// Extract the current state (comonad extract).
    ///
    /// This is equivalent to accessing `current`.
    public func extract() -> State {
        current
    }

    /// Duplicate the stack (comonad duplicate).
    ///
    /// For practical purposes, this is equivalent to `save()`.
    public mutating func duplicate() {
        save()
    }

    /// Extend a function over the stack (comonad extend).
    ///
    /// - Parameter f: A function from Stack to a value
    /// - Returns: The result of applying f to the current stack
    public func extend<T>(_ f: (Self) -> T) -> T {
        f(self)
    }
}
