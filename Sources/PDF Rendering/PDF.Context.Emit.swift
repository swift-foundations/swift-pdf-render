// PDF.Context.Emit.swift
// Verb-as-property accessor for content stream emission

import Geometry_Primitives
import PDF_Standard
import Property_Primitives

extension PDF.Context {
    /// Tag for emit operations.
    public enum Emit {}

    /// Emit operations for content stream output.
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
    /// Emit WinAnsi-encoded bytes at a position.
    ///
    /// Handles coordinate conversion and font/color setup.
    /// Batches multiple text emissions within a single BT/ET block for efficiency.
    public mutating func text(
        _ bytes: [UInt8],
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        guard !base.measurementMode else { return }

        let pdfY = base.pageTop - (position.y - PDF.UserSpace.Y.zero)
        let pdfPosition = PDF.UserSpace.Coordinate(x: position.x, y: pdfY)

        // Open text block if not already open
        if !base.textBlockOpen {
            base.currentPageBuilder.beginText()
            base.textBlockOpen = true
            base.currentTextPosition = nil
        }

        // Set color only if changed
        if base.currentTextColor != color {
            base.setFillColor(color)
            base.currentTextColor = color
        }

        // Set font only if changed
        if base.currentTextFont != font || base.currentTextFontSize != size {
            base.currentPageBuilder.setFont(font, size: size)
            base.currentTextFont = font
            base.currentTextFontSize = size
        }

        // Position text - use relative positioning if we have a previous position
        if let lastPos = base.currentTextPosition {
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
        base.currentTextPosition = pdfPosition

        base.currentPageBuilder.showText(bytes)
    }

    /// Emit a text string at a position (encodes to WinAnsi).
    public mutating func text(
        _ text: String,
        at position: PDF.UserSpace.Coordinate,
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        color: PDF.Color
    ) {
        self.text(
            [UInt8](winAnsi: text, withFallback: true),
            at: position,
            font: font,
            size: size,
            color: color
        )
    }

    /// Emit a line.
    public mutating func line(
        from: PDF.UserSpace.Coordinate,
        to: PDF.UserSpace.Coordinate,
        color: PDF.Color,
        width: PDF.UserSpace.Width
    ) {
        guard !base.measurementMode else { return }

        // Must close text block before graphics operations
        base.flush.text()

        let pdfFromY = base.pageTop - (from.y - PDF.UserSpace.Y.zero)
        let pdfToY = base.pageTop - (to.y - PDF.UserSpace.Y.zero)

        base.setStrokeColor(color)

        base.currentPageBuilder.setLineWidth(width)
        base.currentPageBuilder.moveTo(x: from.x, y: pdfFromY)
        base.currentPageBuilder.lineTo(x: to.x, y: pdfToY)
        base.currentPageBuilder.stroke()
    }

    /// Emit a rectangle.
    public mutating func rectangle(
        _ rect: PDF.UserSpace.Rectangle,
        fill: PDF.Color?,
        stroke: PDF.Stroke?
    ) {
        guard !base.measurementMode else { return }

        // Must close text block before graphics operations
        base.flush.text()

        // In top-left coords: rect.lly is top, rect.lly + rect.height is bottom
        // In PDF bottom-left coords: pdfLly = pageTop - (bottom position as displacement)
        let pdfLly = base.pageTop - (rect.lly + rect.height - PDF.UserSpace.Y.zero)

        if let fill = fill {
            base.setFillColor(fill)
        }

        if let stroke = stroke {
            base.setStrokeColor(stroke.color)
            base.currentPageBuilder.setLineWidth(stroke.width)
        }

        base.currentPageBuilder.rectangle(x: rect.llx, y: pdfLly, width: rect.width, height: rect.height)

        if fill != nil && stroke != nil {
            base.currentPageBuilder.fillAndStroke()
        } else if fill != nil {
            base.currentPageBuilder.fill()
        } else if stroke != nil {
            base.currentPageBuilder.stroke()
        }
    }

    /// Emit an image.
    public mutating func image(
        _ image: ISO_32000.Image,
        in rect: PDF.UserSpace.Rectangle
    ) {
        guard !base.measurementMode else { return }

        // Must close text block before graphics operations
        base.flush.text()

        // Transform Y coordinate (top-left origin -> PDF bottom-left origin)
        let pdfLly = base.pageTop - (rect.lly + rect.height - PDF.UserSpace.Y.zero)

        let pdfRect = PDF.UserSpace.Rectangle(
            x: rect.llx,
            y: pdfLly,
            width: rect.width,
            height: rect.height
        )

        base.currentPageBuilder.drawImage(image, in: pdfRect)
    }

    /// Emit a circle.
    public mutating func circle(
        center: PDF.UserSpace.Coordinate,
        radius: PDF.UserSpace.Length,
        fill: PDF.Color?,
        stroke: PDF.Color?,
        strokeWidth: PDF.UserSpace.Width = .init(1)
    ) {
        guard !base.measurementMode else { return }

        // Must close text block before graphics operations
        base.flush.text()

        // Transform Y coordinate (top-left origin -> PDF bottom-left origin)
        let pdfCenterY = base.pageTop - (center.y - PDF.UserSpace.Y.zero)
        let pdfCenter = PDF.UserSpace.Point(
            x: center.x,
            y: pdfCenterY
        )
        let circle = PDF.UserSpace.Circle(
            center: pdfCenter,
            radius: radius
        )

        if let fill = fill {
            base.setFillColor(fill)
        }

        if let stroke = stroke {
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
