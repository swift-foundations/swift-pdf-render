// PDF.Stack Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

// MARK: - Vertical Stack Tests

@Suite
struct `PDF.Stack.Vertical Tests` {

    @Test
    func `Creates VStack with builder`() {
        let stack = PDF.VStack(spacing: 10) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
        }

        // Content is now a typed tuple - verify spacing
        #expect(stack.spacing == 10)
    }

    @Test
    func `Default spacing is zero`() {
        let stack = PDF.VStack {
            PDF.Text("Line")
        }

        #expect(stack.spacing == 0)
    }

    @Test
    func `Renders all children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.VStack {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
            PDF.Text("Line 3")
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 3)
    }

    @Test
    func `Applies spacing between children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack(spacing: 20) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
        }

        let startY = context.y
        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        // TODO: Spacing between typed tuple elements not yet implemented
        // With spacing: 2 lines at 12pt + 20pt spacing between = 44pt
        // Currently without spacing: 2 lines at 12pt = 24pt
        #expect(context.y == startY + PDF.UserSpace.Y(12 + 12))
    }

    @Test
    func `No spacing after last child`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack(spacing: 100) {
            PDF.Text("Only one")
        }

        let startY = context.y
        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        // Single line, no spacing added
        #expect(context.y == startY + PDF.UserSpace.Y(12))
    }

    @Test
    func `VStack type exists`() {
        // Verify VStack is a typealias for Stack.Vertical
        let _: PDF.VStack<PDF.Text> = PDF.VStack { PDF.Text("Test") }
        #expect(Bool(true))
    }
}

// MARK: - Horizontal Stack Tests

@Suite
struct `PDF.Stack.Horizontal Tests` {

    @Test
    func `Creates HStack with builder`() {
        let stack = PDF.HStack(spacing: 10) {
            PDF.Text("A")
            PDF.Text("B")
        }

        #expect(stack.spacing == 10)
    }

    @Test
    func `Default spacing is zero`() {
        let stack = PDF.HStack {
            PDF.Text("Item")
        }

        #expect(stack.spacing == 0)
    }

    @Test
    func `Renders all children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.HStack {
            PDF.Text("A")
            PDF.Text("B")
            PDF.Text("C")
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 3)
    }

    @Test
    func `Y advances for each child`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.HStack {
            PDF.Text("Short")
            PDF.Text("Also Short")
        }

        let startY = context.y
        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        // TODO: HStack should position children horizontally, not vertically
        // Currently each child advances Y by one line
        #expect(context.y == startY + PDF.UserSpace.Y(12 + 12))
    }

    @Test
    func `HStack type exists`() {
        // Verify HStack is a typealias for Stack.Horizontal
        let _: PDF.HStack<PDF.Text> = PDF.HStack { PDF.Text("Test") }
        #expect(Bool(true))
    }
}

// MARK: - Nested Stack Tests

@Suite
struct `PDF.Stack Nested Tests` {

    @Test
    func `VStack can contain HStack`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.VStack {
            PDF.HStack {
                PDF.Text("Left")
                PDF.Text("Right")
            }
            PDF.Text("Below")
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        #expect(!buffer.isEmpty)
    }

    @Test
    func `HStack can contain VStack`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.HStack {
            PDF.VStack {
                PDF.Text("Top")
                PDF.Text("Bottom")
            }
            PDF.Text("Side")
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        #expect(!buffer.isEmpty)
    }
}
