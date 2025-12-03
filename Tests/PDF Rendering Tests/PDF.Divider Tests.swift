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
    func `Creates graphics operation`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDF.Divider()
        var buffer: [PDF.Render.Operation] = []
        PDF.render(divider, into: &buffer, context: &context)

        let graphicsOps = buffer.filter {
            if case .graphics = $0 { return true }
            return false
        }

        #expect(graphicsOps.count == 1)
    }

    @Test
    func `Creates line graphics operation`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDF.Divider()
        var buffer: [PDF.Render.Operation] = []
        PDF.render(divider, into: &buffer, context: &context)

        if case .graphics(let graphicsOp) = buffer[0] {
            if case .line(let from, let to, let color, let width) = graphicsOp {
                #expect(from.x == 72)
                #expect(to.x == 472)  // 72 + 400
                #expect(color == .gray50)
                #expect(width == 0.5)
            } else {
                Issue.record("Expected line operation")
            }
        } else {
            Issue.record("Expected graphics operation")
        }
    }

    @Test
    func `Advances Y by padding plus thickness`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDF.Divider(thickness: 2.0, padding: 10)
        let startY = context.y
        var buffer: [PDF.Render.Operation] = []
        PDF.render(divider, into: &buffer, context: &context)

        // padding before (10) + thickness (2) + padding after (10) = 22
        #expect(context.y == startY + 22)
    }

    @Test
    func `Line spans available width`() {
        var context = PDF.Context(
            x: 100,
            y: 72,
            availableWidth: 200,
            availableHeight: 700
        )

        let divider = PDF.Divider()
        var buffer: [PDF.Render.Operation] = []
        PDF.render(divider, into: &buffer, context: &context)

        if case .graphics(let graphicsOp) = buffer[0] {
            if case .line(let from, let to, _, _) = graphicsOp {
                #expect(from.x == 100)
                #expect(to.x == 300)  // 100 + 200
            }
        }
    }

    @Test
    func `Uses specified color`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let divider = PDF.Divider(color: .blue)
        var buffer: [PDF.Render.Operation] = []
        PDF.render(divider, into: &buffer, context: &context)

        if case .graphics(let graphicsOp) = buffer[0] {
            if case .line(_, _, let color, _) = graphicsOp {
                #expect(color == .blue)
            }
        }
    }
}
