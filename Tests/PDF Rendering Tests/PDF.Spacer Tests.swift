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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(spacer, into: &buffer, context: &context)

        #expect(buffer.isEmpty)
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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(spacer, into: &buffer, context: &context)

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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(spacer, into: &buffer, context: &context)

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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(spacer, into: &buffer, context: &context)

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

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        // 72 + "Before" (12) + Spacer (50) + "After" (12) = 146
        #expect(context.y == 146)
    }
}
