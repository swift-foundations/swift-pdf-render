// PDF.Spacer Tests.swift

import PDF_Rendering_Test_Support
import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.Spacer Tests` {

    // MARK: - Construction

    @Test
    func `Creates spacer with height`() {
        let spacer = PDF.Spacer(50)
        #expect(spacer.height == 50)
    }

    @Test
    func `Creates zero-height spacer`() {
        let spacer = PDF.Spacer(0)
        #expect(spacer.height == 0)
    }

    // MARK: - Rendering

    @Test
    func `Does not add content to stream`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let spacer = PDF.Spacer(50)
        PDF.Spacer._render(spacer, context: &context)

        // Spacer doesn't emit any content
        #expect(context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Advances Y by specified height`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let spacer = PDF.Spacer(50)
        PDF.Spacer._render(spacer, context: &context)

        #expect(context.layoutBox.lly == 122)
    }

    @Test
    func `Zero height does not advance Y`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let spacer = PDF.Spacer(0)
        PDF.Spacer._render(spacer, context: &context)

        #expect(context.layoutBox.lly == 72)
    }

    @Test
    func `Does not affect X position`() {
        var context = PDF.Context(
            x: 100,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let spacer = PDF.Spacer(50)
        PDF.Spacer._render(spacer, context: &context)

        #expect(context.layoutBox.llx == 100)
    }

    @Test
    func `Works in VStack`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack {
            PDF.Text("Before")
            PDF.Spacer(50)
            PDF.Text("After")
        }

        PDF.VStack._render(stack, context: &context)

        // 72 + "Before" (12) + Spacer (50) + "After" (12) = 146
        #expect(context.layoutBox.lly == 146)
    }
}
