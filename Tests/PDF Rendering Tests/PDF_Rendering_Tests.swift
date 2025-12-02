// PDF_Rendering_Tests.swift

import Testing
@testable import PDF_Rendering

@Suite("PDF Rendering")
struct PDFRenderingTests {

    @Test("PDFText renders single line")
    func textSingleLine() {
        var context = PDF.RenderContext(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let text = PDFText("Hello, World!")
        let content = text.render(context: &context)

        #expect(!content.operations.isEmpty)
        #expect(context.y > 72) // Should have advanced
    }

    @Test("PDFText wraps long text")
    func textWrapping() {
        var context = PDF.RenderContext(
            x: 72,
            y: 72,
            availableWidth: 100, // Very narrow
            availableHeight: 700
        )

        let text = PDFText("This is a longer text that should wrap to multiple lines")
        let content = text.render(context: &context)

        // With narrow width, should have multiple lines
        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count > 1)
    }

    @Test("PDFVStack arranges vertically")
    func vstackLayout() {
        var context = PDF.RenderContext(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDFVStack(spacing: 10) {
            PDFText("Line 1")
            PDFText("Line 2")
            PDFText("Line 3")
        }

        let content = stack.render(context: &context)

        // Should have 3 text operations
        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count == 3)
    }

    @Test("PDFSpacer adds space")
    func spacerAdvancesY() {
        var context = PDF.RenderContext(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDFSpacer(50)
        _ = spacer.render(context: &context)

        #expect(context.y == 122) // 72 + 50
    }

    @Test("PDFDivider creates line")
    func dividerCreatesLine() {
        var context = PDF.RenderContext(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDFDivider()
        let content = divider.render(context: &context)

        // Should have one graphics operation
        let graphicsOps = content.operations.filter {
            if case .graphics = $0 { return true }
            return false
        }
        #expect(graphicsOps.count == 1)
    }

    @Test("RenderContext from page")
    func contextFromPage() {
        let page = PDF.Page(
            paperSize: .letter,
            margins: .standard
        ) {
            PDF.Content.text("Test", at: .init(x: 0, y: 0))
        }

        let context = PDF.RenderContext(page: page)

        #expect(context.x == 72) // Standard margin
        #expect(context.y == 72)
        #expect(context.availableWidth == 612 - 144) // Letter width minus margins
    }
}
