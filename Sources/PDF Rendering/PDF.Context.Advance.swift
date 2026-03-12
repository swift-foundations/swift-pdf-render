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
        // WORKAROUND: Cannot use += with typed geometric values
        // WHY: PDF.UserSpace types don't provide compound assignment operators
        // WHEN TO REMOVE: When typed += operators are added to geometric types
        // swiftlint:disable:next shorthand_operator
        base.layoutBox.lly = base.layoutBox.lly + amount
    }

    /// Advance Y position by one line.
    public mutating func line() {
        // swiftlint:disable:next shorthand_operator
        base.layoutBox.lly = base.layoutBox.lly + base.style.line.height
    }

    /// Advance X position by specified amount (for horizontal layout).
    public mutating func x(_ amount: PDF.UserSpace.Width) {
        // swiftlint:disable:next shorthand_operator
        base.layoutBox.llx = base.layoutBox.llx + amount
    }
}
