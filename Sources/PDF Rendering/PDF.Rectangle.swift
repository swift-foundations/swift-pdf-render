// PDF.Rectangle.swift
// A styled rectangle view for PDF rendering

public import PDF_Standard

extension PDF.Rectangle: PDF.View {
    
    public var body: Never {
        fatalError("PDF.Rectangle is a leaf view")
    }
    
    public static func _render(_ view: Self, context: inout PDF.Context) {
        // Check for page break before rendering
        context.checkPageBreak(needing: view.rect.height)
        
        // Emit rectangle at current position + rectangle's offset
        let renderRect = PDF.UserSpace.Rectangle(
            x: context.x + view.rect.llx,
            y: context.y + view.rect.lly,
            width: view.rect.width,
            height: view.rect.height
        )
        
        context.emitRectangle(
            renderRect,
            fill: view.fill,
            stroke: view.stroke,
            strokeWidth: .init(view.strokeWidth)
        )
        
        // Advance Y by the rectangle height
        context.advance(PDF.UserSpace.Y(view.rect.height.value))
    }
}

