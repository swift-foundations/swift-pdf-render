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
            availableHeight: 700
        )

        let text = PDF.Text("Hello, World!")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        #expect(buffer.count == 1)
    }

    @Test
    func `Advances Y after rendering`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.2
        )

        let startY = context.y
        let text = PDF.Text("Hello")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        #expect(context.y == startY + PDF.UserSpace.Y(14.4))
    }

    @Test
    func `Uses context font when not specified`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            font: .courier.bold
        )

        let text = PDF.Text("Hello")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        if case .text(let op) = buffer[0] {
            #expect(op.font == .courier.bold)
        } else {
            Issue.record("Expected text operation")
        }
    }

    @Test
    func `Overrides context font when specified`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            font: .helvetica
        )

        let text = PDF.Text("Hello", font: .times)
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        if case .text(let op) = buffer[0] {
            #expect(op.font == .times)
        } else {
            Issue.record("Expected text operation")
        }
    }

    // MARK: - Text Wrapping

    @Test
    func `Wraps long text to multiple lines`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,
            availableHeight: 700
        )

        let text = PDF.Text("This is a longer text that should wrap to multiple lines")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count > 1)
    }

    @Test
    func `Each wrapped line advances Y`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.2
        )

        let startY = context.y
        let text = PDF.Text("This is a longer text that should wrap")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        let lineCount = buffer.count
        let expectedAdvance = PDF.UserSpace.Y(Double(lineCount) * 14.4)

        #expect(abs((context.y - startY - expectedAdvance).value) < 0.01)
    }

    @Test
    func `Word that exceeds width gets its own line`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 50,
            availableHeight: 700
        )

        let text = PDF.Text("Supercalifragilisticexpialidocious")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        #expect(!buffer.isEmpty)
    }

    // MARK: - Text Position

    @Test
    func `Text positioned at context coordinates`() {
        var context = PDF.Context(
            x: 100,
            y: 200,
            availableWidth: 400,
            availableHeight: 700
        )

        let text = PDF.Text("Hello")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        if case .text(let op) = buffer[0] {
            #expect(op.position.x == 100)
            // Y position is at baseline = context.y + ascender height
            // Helvetica ascender at 12pt is ~8.616pt
            let expectedBaselineY = PDF.UserSpace.Y(200) + PDF.UserSpace.Y(context.font.metrics.ascender(atSize: context.fontSize))
            #expect(op.position.y == expectedBaselineY)
        } else {
            Issue.record("Expected text operation")
        }
    }

    // MARK: - Empty Text

    @Test
    func `Empty text produces single empty line`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let text = PDF.Text("")
        var buffer: [PDF.Render.Operation] = []
        PDF.render(text, into: &buffer, context: &context)

        #expect(buffer.count == 1)
    }
}
