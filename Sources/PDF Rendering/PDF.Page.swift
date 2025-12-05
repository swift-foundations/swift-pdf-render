// PDF.Page.swift
// Rendering extensions for ISO_32000.Page

public import PDF_Standard

// MARK: - Create Page from Render Operations

extension PDF.Page {
    /// Create a page from render operations
    ///
    /// Converts high-level render operations to a PDF content stream,
    /// transforming from top-left to bottom-left coordinates.
    ///
    /// - Parameters:
    ///   - mediaBox: Page size
    ///   - operations: Render operations (in top-left coordinates)
    ///   - annotations: Page annotations
    public init(
        mediaBox: ISO_32000.UserSpace.Rectangle = .a4,
        operations: [PDF.Render.Operation],
        annotations: [PDF.Annotation] = []
    ) {
        let pageHeight: PDF.UserSpace.Height = mediaBox.height
        
        // Build content stream with coordinate conversion
        let contentStream: ISO_32000.ContentStream = .init { (builder: inout ISO_32000.ContentStream.Builder) in
            for op in operations {
                switch op {
                case .text(let textOp):
                    // Transform from top-left to bottom-left coordinates
                    let pdfY = ISO_32000.UserSpace.Y(PDF.UserSpace.Unit(pageHeight.value - textOp.position.y.value))
                    
                    builder.beginText()
                    
                    // Set color
                    switch textOp.color {
                    case .gray(let g):
                        builder.setFillColorGray(g)
                    case .rgb(let r, let g, let b):
                        builder.setFillColorRGB(r: r, g: g, b: b)
                    case .cmyk(let c, let m, let y, let k):
                        builder.setFillColorCMYK(c: c, m: m, y: y, k: k)
                    }
                    
                    builder.setFont(textOp.font, size: textOp.size)
                    builder.moveText(x: textOp.position.x, y: pdfY)
                    builder.showText(textOp.text)
                    builder.endText()
                    
                case .graphics(let graphicsOp):
                    switch graphicsOp {
                    case .line(let from, let to, let color, let width):
                        let pdfFromY = PDF.UserSpace.Y(PDF.UserSpace.Unit(pageHeight.value - from.y.value))
                        let pdfToY = PDF.UserSpace.Y(PDF.UserSpace.Unit(pageHeight.value - to.y.value))
                        
                        switch color {
                        case .gray(let g):
                            builder.setStrokeColorGray(g)
                        case .rgb(let r, let g, let b):
                            builder.setStrokeColorRGB(r: r, g: g, b: b)
                        case .cmyk(let c, let m, let y, let k):
                            builder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
                        }
                        
                        builder.setLineWidth(width)
                        builder.moveTo(x: from.x, y: pdfFromY)
                        builder.lineTo(x: to.x, y: pdfToY)
                        builder.stroke()
                        
                    case .rectangle(let rect, let fill, let stroke, let strokeWidth):
                        // Transform Y coordinate (rect uses top-left origin, PDF uses bottom-left)
                        let pdfY: PDF.UserSpace.Y = .init(pageHeight.value - rect.lly.value - rect.height.value)
                        
                        if let fill = fill {
                            switch fill {
                            case .gray(let g):
                                builder.setFillColorGray(g)
                            case .rgb(let r, let g, let b):
                                builder.setFillColorRGB(r: r, g: g, b: b)
                            case .cmyk(let c, let m, let y, let k):
                                builder.setFillColorCMYK(c: c, m: m, y: y, k: k)
                            }
                        }
                        
                        if let stroke = stroke {
                            switch stroke {
                            case .gray(let g):
                                builder.setStrokeColorGray(g)
                            case .rgb(let r, let g, let b):
                                builder.setStrokeColorRGB(r: r, g: g, b: b)
                            case .cmyk(let c, let m, let y, let k):
                                builder.setStrokeColorCMYK(c: c, m: m, y: y, k: k)
                            }
                            builder.setLineWidth(strokeWidth)
                        }
                        
                        builder.rectangle(x: rect.llx, y: pdfY, width: rect.width, height: rect.height)
                        
                        if fill != nil && stroke != nil {
                            builder.fillAndStroke()
                        } else if fill != nil {
                            builder.fill()
                        } else if stroke != nil {
                            builder.stroke()
                        }
                    }
                }
            }
        }
        
        // Build font resources from content stream
        var fontResources: [ISO_32000.COS.Name: ISO_32000.Font] = [:]
        for font in contentStream.fontsUsed {
            fontResources[font.resourceName] = font
        }
        
        self.init(
            mediaBox: mediaBox,
            content: contentStream,
            resources: ISO_32000.Resources(fonts: fontResources),
            annotations: annotations
        )
    }
}
