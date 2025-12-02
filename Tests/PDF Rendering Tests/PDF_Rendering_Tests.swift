// PDF_Rendering_Tests.swift

import Testing
@testable import PDF_Rendering

@Suite("PDF Rendering")
struct PDFRenderingTests {

    @Test("PDF.Text renders single line")
    func textSingleLine() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let text = PDF.Text("Hello, World!")
        let content = text.render(context: &context)

        #expect(!content.operations.isEmpty)
        #expect(context.y > 72)
    }

    @Test("PDF.Text wraps long text")
    func textWrapping() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,
            availableHeight: 700
        )

        let text = PDF.Text("This is a longer text that should wrap to multiple lines")
        let content = text.render(context: &context)

        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count > 1)
    }

    @Test("PDF.VStack arranges vertically")
    func vstackLayout() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.VStack(spacing: 10) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
            PDF.Text("Line 3")
        }

        let content = stack.render(context: &context)

        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }
        #expect(textOps.count == 3)
    }

    @Test("PDF.Stack.Vertical is aliased as PDF.VStack")
    func vstackTypealias() {
        let _: PDF.VStack = PDF.Stack.Vertical(spacing: 0, children: [])
        let _: PDF.Stack.Vertical = PDF.VStack(spacing: 0, children: [])
    }

    @Test("PDF.Stack.Horizontal is aliased as PDF.HStack")
    func hstackTypealias() {
        let _: PDF.HStack = PDF.Stack.Horizontal(spacing: 0, children: [])
        let _: PDF.Stack.Horizontal = PDF.HStack(spacing: 0, children: [])
    }

    @Test("PDF.Spacer adds space")
    func spacerAdvancesY() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDF.Spacer(50)
        _ = spacer.render(context: &context)

        #expect(context.y == 122)
    }

    @Test("PDF.Divider creates line")
    func dividerCreatesLine() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDF.Divider()
        let content = divider.render(context: &context)

        let graphicsOps = content.operations.filter {
            if case .graphics = $0 { return true }
            return false
        }
        #expect(graphicsOps.count == 1)
    }

    @Test("PDF.Context from page")
    func contextFromPage() {
        let page = PDF.Page(
            paperSize: .letter,
            margins: .standard
        ) {
            PDF.Content.text("Test", at: .init(x: 0, y: 0))
        }

        let context = PDF.Context(page: page)

        #expect(context.x == 72)
        #expect(context.y == 72)
        #expect(context.availableWidth == 612 - 144)
    }
}
