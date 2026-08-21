import Geometry_Primitives
import Layout_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {

    public enum Advance {}

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

    public mutating func callAsFunction(_ amount: PDF.UserSpace.Height) {
        base.layout.box.lly += amount
    }

    public mutating func line() {
        base.layout.box.lly += base.style.line.height
    }

    public mutating func x(_ amount: PDF.UserSpace.Width) {
        base.layout.box.llx += amount
    }
}
