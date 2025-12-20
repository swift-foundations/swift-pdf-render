// PDF.Stack Tests.swift

import PDF_Standard
import Testing

@testable import PDF_Rendering

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
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.VStack {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
            PDF.Text("Line 3")
        }

        PDF.VStack._render(stack, context: &context)

        // Content stream should have data for all 3 texts
        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Applies spacing between children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack(spacing: 20) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
        }

        PDF.VStack._render(stack, context: &context)

        // 72 + line 1 (12) + spacing (20) + line 2 (12) = 116
        #expect(context.layoutBox.lly == 116)
    }

    @Test
    func `No spacing after last child`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.VStack(spacing: 100) {
            PDF.Text("Only one")
        }

        PDF.VStack._render(stack, context: &context)

        // 72 + single line (12), no spacing added = 84
        #expect(context.layoutBox.lly == 84)
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
        let stack = PDF.HStack.horizontal(spacing: 10) {
            PDF.Text("A")
            PDF.Text("B")
        }

        #expect(stack.spacing == 10)
    }

    @Test
    func `Default spacing is zero`() {
        let stack = PDF.HStack.horizontal {
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
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.HStack.horizontal {
            PDF.Text("A")
            PDF.Text("B")
            PDF.Text("C")
        }

        PDF.HStack._render(stack, context: &context)

        // Content stream should have data
        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Y advances by max child height`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.0
        )

        let stack = PDF.HStack.horizontal {
            PDF.Text("Short")
            PDF.Text("Also Short")
        }

        PDF.HStack._render(stack, context: &context)

        // HStack positions children horizontally, Y advances by max height (one line)
        // 72 + 12 = 84
        #expect(context.layoutBox.lly == 84)
    }

    @Test
    func `HStack type exists`() {
        // Verify HStack is a typealias for Stack
        let _: PDF.HStack<PDF.Text> = PDF.HStack.horizontal { PDF.Text("Test") }
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
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.VStack {
            PDF.HStack.horizontal {
                PDF.Text("Left")
                PDF.Text("Right")
            }
            PDF.Text("Below")
        }

        PDF.VStack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `HStack can contain VStack`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.HStack.horizontal {
            PDF.VStack {
                PDF.Text("Top")
                PDF.Text("Bottom")
            }
            PDF.Text("Side")
        }

        PDF.HStack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }
}
