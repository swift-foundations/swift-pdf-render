// PDF.Divider Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

@Suite
struct `PDF.Divider Tests` {

    // MARK: - Construction

    @Test
    func `Creates divider with defaults`() {
        let divider = PDF.Divider()

        #expect(divider.color == .gray50)
        #expect(divider.thickness == 0.5)
        #expect(divider.padding == 6)
    }

    @Test
    func `Creates divider with custom values`() {
        let divider = PDF.Divider(
            color: .red,
            thickness: 2.0,
            padding: 10
        )

        #expect(divider.color == .red)
        #expect(divider.thickness == 2.0)
        #expect(divider.padding == 10)
    }

    // MARK: - Rendering

    @Test
    func `Creates graphics content`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792
        )

        let divider = PDF.Divider()
        PDF.Divider._render(divider, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Advances Y by padding plus thickness`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            pageHeight: 792
        )

        let divider = PDF.Divider(thickness: 2.0, padding: 10)
        PDF.Divider._render(divider, context: &context)

        // 72 + padding before (10) + thickness (2) + padding after (10) = 94
        #expect(context.y == 94)
    }
}
