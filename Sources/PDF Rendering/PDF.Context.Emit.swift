import Byte_Primitives
import Geometry_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {

    public enum Emit {}

    public var emit: Property<Emit, Self> {
        get { Property(self) }
        _modify {
            var property = Property<Emit, Self>(self)
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property where Tag == PDF.Context.Emit, Base == PDF.Context {

    public mutating func text(
        _ bytes: [Byte],
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        guard !base.mode.measurement else { return }

        let pdfY = base.pageTop - (position.y - PDF.UserSpace.Y.zero)
        let pdfPosition = PDF.UserSpace.Coordinate(x: position.x, y: pdfY)

        if !base.text.blockOpen {
            base.currentPageBuilder.beginText()
            base.text.blockOpen = true
            base.text.position = nil
        }

        if base.text.color != color {
            base.setFillColor(color)
            base.text.color = color
        }

        if base.text.font != font || base.text.fontSize != size {
            base.currentPageBuilder.setFont(font, size: size)
            base.text.font = font
            base.text.fontSize = size
        }

        if let lastPos = base.text.position {
            base.currentPageBuilder.moveText(
                dx: pdfPosition.x - lastPos.x,
                dy: pdfPosition.y - lastPos.y
            )
        } else {
            base.currentPageBuilder.moveText(
                dx: pdfPosition.x - .zero,
                dy: pdfPosition.y - .zero
            )
        }
        base.text.position = pdfPosition

        base.currentPageBuilder.showText(bytes)
    }

    public mutating func text(
        _ text: String,
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        self.text(
            [Byte](winAnsi: text, withFallback: true),
            at: position,
            font: font,
            size: size,
            color: color
        )
    }

    public mutating func line(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width
    ) {
        guard !base.mode.measurement else { return }

        base.flush.text()

        let pdfFromY = base.pageTop - (from.y - PDF.UserSpace.Y.zero)
        let pdfToY = base.pageTop - (to.y - PDF.UserSpace.Y.zero)

        base.setStrokeColor(color)

        base.currentPageBuilder.setLineWidth(width)
        base.currentPageBuilder.moveTo(x: from.x, y: pdfFromY)
        base.currentPageBuilder.lineTo(x: to.x, y: pdfToY)
        base.currentPageBuilder.stroke()
    }

    public mutating func rectangle(
        _ rect: PDF.UserSpace.Rectangle,
        fill: PDF.Color?,
        stroke: PDF.Stroke?
    ) {
        guard !base.mode.measurement else { return }

        base.flush.text()

        let pdfLly = base.pageTop - (rect.lly + rect.height - PDF.UserSpace.Y.zero)

        if let fill {
            base.setFillColor(fill)
        }

        if let stroke {
            base.setStrokeColor(stroke.color)
            base.currentPageBuilder.setLineWidth(stroke.width)
        }

        base.currentPageBuilder.rectangle(
            x: rect.llx,
            y: pdfLly,
            width: rect.width,
            height: rect.height
        )

        if fill != nil && stroke != nil {
            base.currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            base.currentPageBuilder.fill()
        } else if stroke != nil {
            base.currentPageBuilder.stroke()
        }
    }

    public mutating func image(
        _ image: ISO_32000.Image,
        in rect: PDF.UserSpace.Rectangle
    ) {
        guard !base.mode.measurement else { return }

        base.flush.text()

        let pdfLly = base.pageTop - (rect.lly + rect.height - PDF.UserSpace.Y.zero)

        let pdfRect = PDF.UserSpace.Rectangle(
            x: rect.llx,
            y: pdfLly,
            width: rect.width,
            height: rect.height
        )

        base.currentPageBuilder.drawImage(image, in: pdfRect)
    }

    public mutating func circle(
        center: PDF.UserSpace.Coordinate,
        radius: PDF.UserSpace.Length,
        fill: PDF.Color?,
        stroke: PDF.Color?,
        strokeWidth: PDF.UserSpace.Width = .init(1)
    ) {
        guard !base.mode.measurement else { return }

        base.flush.text()

        let pdfCenterY = base.pageTop - (center.y - PDF.UserSpace.Y.zero)
        let pdfCenter = PDF.UserSpace.Point(
            x: center.x,
            y: pdfCenterY
        )
        let circle = PDF.UserSpace.Circle(
            center: pdfCenter,
            radius: radius
        )

        if let fill {
            base.setFillColor(fill)
        }

        if let stroke {
            base.setStrokeColor(stroke)
            base.currentPageBuilder.setLineWidth(strokeWidth)
        }

        base.currentPageBuilder.circle(circle)

        if fill != nil && stroke != nil {
            base.currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            base.currentPageBuilder.fill()
        } else if stroke != nil {
            base.currentPageBuilder.stroke()
        }
    }
}
