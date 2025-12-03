// PDF.Spacer Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

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
    func `Does not add operations`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDF.Spacer(50)
        _ = PDF.render(spacer, context: &context)

        #expect(context.currentPageOperations.isEmpty)
    }

    @Test
    func `Advances Y by specified height`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDF.Spacer(50)
        _ = PDF.render(spacer, context: &context)

        #expect(context.y == 122)
    }

    @Test
    func `Zero height does not advance Y`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDF.Spacer(0)
        _ = PDF.render(spacer, context: &context)

        #expect(context.y == 72)
    }

    @Test
    func `Does not affect X position`() {
        var context = PDF.Context(
            x: 100,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let spacer = PDF.Spacer(50)
        _ = PDF.render(spacer, context: &context)

        #expect(context.x == 100)
    }

    @Test
    func `Works in VStack`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack {
            PDF.Text("Before")
            PDF.Spacer(50)
            PDF.Text("After")
        }

        let startY = context.y
        _ = PDF.render(stack, context: &context)

        // "Before" (12) + Spacer (50) + "After" (12) = 74
        #expect(context.y == startY + 74)
    }
}
