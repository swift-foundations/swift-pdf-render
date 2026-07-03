// PDF.Context.Advance.swift
// Verb-as-property accessor for position advancement

import Geometry_Primitives
import Layout_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {
    /// Tag for advance operations.
    public enum Advance {}

    /// Advance operations for position movement.
    public var advance: Property<Advance, Self> {
        get { Property(self) }
        _modify {
            var property = Property<Advance, Self>(self)
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property where Tag == PDF.Context.Advance, Base == PDF.Context {
    /// Advance Y position by specified amount.
    public mutating func callAsFunction(_ amount: PDF.UserSpace.Height) {
        base.layout.box.lly += amount
    }

    /// Advance Y position by one line.
    public mutating func line() {
        base.layout.box.lly += base.style.line.height
    }

    /// Advance X position by specified amount (for horizontal layout).
    public mutating func x(_ amount: PDF.UserSpace.Width) {
        base.layout.box.llx += amount
    }
}
