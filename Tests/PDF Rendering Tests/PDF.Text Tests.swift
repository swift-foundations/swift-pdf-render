// PDF.Text Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

@Suite
struct `PDF.Text Tests` {

    // MARK: - Construction

    @Test
    func `Creates text with content`() {
        let text = PDF.Text("Hello, World!")
        #expect(text.text == "Hello, World!")
    }

    @Test
    func `Creates text with all parameters`() {
        let text = PDF.Text(
            "Custom text",
            font: .times,
            fontSize: 18,
            color: .blue
        )

        #expect(text.text == "Custom text")
        #expect(text.font == .times)
        #expect(text.fontSize == 18)
        #expect(text.color == .blue)
    }

    @Test
    func `Optional parameters default to nil`() {
        let text = PDF.Text("Simple")

        #expect(text.font == nil)
        #expect(text.fontSize == nil)
        #expect(text.color == nil)
    }

    // MARK: - Single Line Rendering

    @Test
    func `Renders single line text`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792
        )

        let text = PDF.Text("Hello, World!")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Advances Y after rendering`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792,
            fontSize: 12,
            lineHeight: 1.2
        )

        let text = PDF.Text("Hello")
        PDF.Text._render(text, context: &context)

        // 72 + 12 * 1.2 = 86.4 (tolerance for floating point)
        #expect(abs(context.y.value - 86.4) < 0.001)
    }

    @Test
    func `Uses context font when not specified`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792,
            font: .courier.bold
        )

        let text = PDF.Text("Hello")
        PDF.Text._render(text, context: &context)

        // Font should be in the fonts used
        #expect(context.currentPageBuilder.fontsUsed.contains(.courier.bold))
    }

    @Test
    func `Overrides context font when specified`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792,
            font: .helvetica
        )

        let text = PDF.Text("Hello", font: .times)
        PDF.Text._render(text, context: &context)

        // Times should be in the fonts used
        #expect(context.currentPageBuilder.fontsUsed.contains(.times))
    }

    // MARK: - Text Wrapping

    @Test
    func `Wraps long text to multiple lines`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,
            availableHeight: 700,
            pageHeight: 792
        )

        let text = PDF.Text("This is a longer text that should wrap to multiple lines")
        let startY = context.y
        PDF.Text._render(text, context: &context)

        // Y should have advanced by more than one line
        let lineHeight = context.lineHeightPoints
        #expect(context.y.value - startY.value > lineHeight.value)
    }

    @Test
    func `Each wrapped line advances Y`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,
            availableHeight: 700,
            pageHeight: 792,
            fontSize: 12,
            lineHeight: 1.2
        )

        let text = PDF.Text("This is a longer text that should wrap")
        let startY = context.y.value
        PDF.Text._render(text, context: &context)

        // Each line advances by fontSize * lineHeight = 12 * 1.2 = 14.4
        // The final Y should be startY + (lineCount * 14.4)
        let linesRendered = (context.y.value - startY) / 14.4
        #expect(linesRendered >= 1)
    }

    @Test
    func `Word that exceeds width gets its own line`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 50,
            availableHeight: 700,
            pageHeight: 792
        )

        let text = PDF.Text("Supercalifragilisticexpialidocious")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    // MARK: - Empty Text

    @Test
    func `Empty text produces single empty line`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792
        )

        let text = PDF.Text("")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }
}
