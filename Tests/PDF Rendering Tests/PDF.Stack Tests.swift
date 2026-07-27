// PDF.Stack Tests.swift

import Layout_Primitives
import PDF_Rendering_Test_Support
import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.Stack Tests` {

    // MARK: - Vertical

    @Test
    func `Creates vertical stack with builder`() {
        let stack = PDF.Stack(.vertical, spacing: 10) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
        }

        #expect(stack.spacing == 10)
    }

    @Test
    func `Default axis is vertical`() {
        let stack = PDF.Stack {
            PDF.Text("Line")
        }

        #expect(stack.spacing == 0)
        #expect(stack.axis == .vertical)
    }

    @Test
    func `Vertical renders all children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.Stack {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
            PDF.Text("Line 3")
        }

        PDF.Stack._render(stack, context: &context)

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

        let stack = PDF.Stack(.vertical, spacing: 20) {
            PDF.Text("Line 1")
            PDF.Text("Line 2")
        }

        PDF.Stack._render(stack, context: &context)

        // 72 + line 1 (12) + spacing (20) + line 2 (12) = 116
        #expect(context.layout.box.lly == 116)
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

        let stack = PDF.Stack(.vertical, spacing: 100) {
            PDF.Text("Only one")
        }

        PDF.Stack._render(stack, context: &context)

        // 72 + single line (12), no spacing added = 84
        #expect(context.layout.box.lly == 84)
    }

    @Test
    func `Stack type resolves correctly`() {
        let _: PDF.Stack<PDF.Text> = PDF.Stack { PDF.Text("Test") }
        #expect(Bool(true))
    }

    // MARK: - Horizontal

    @Test
    func `Creates horizontal stack with builder`() {
        let stack = PDF.Stack(.horizontal, spacing: 10) {
            PDF.Text("A")
            PDF.Text("B")
        }

        #expect(stack.spacing == 10)
    }

    @Test
    func `Horizontal default spacing is zero`() {
        let stack = PDF.Stack(.horizontal) {
            PDF.Text("Item")
        }

        #expect(stack.spacing == 0)
    }

    @Test
    func `Horizontal renders all children`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.Stack(.horizontal) {
            PDF.Text("A")
            PDF.Text("B")
            PDF.Text("C")
        }

        PDF.Stack._render(stack, context: &context)

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

        let stack = PDF.Stack(.horizontal) {
            PDF.Text("Short")
            PDF.Text("Also Short")
        }

        PDF.Stack._render(stack, context: &context)

        // HStack positions children horizontally, Y advances by max height (one line)
        // 72 + 12 = 84
        #expect(context.layout.box.lly == 84)
    }

    @Test
    func `Horizontal stack type resolves correctly`() {
        let _: PDF.Stack<PDF.Text> = PDF.Stack(.horizontal) { PDF.Text("Test") }
        #expect(Bool(true))
    }

    // MARK: - Nesting

    @Test
    func `Vertical can contain horizontal`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.Stack {
            PDF.Stack(.horizontal) {
                PDF.Text("Left")
                PDF.Text("Right")
            }
            PDF.Text("Below")
        }

        PDF.Stack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Horizontal can contain vertical`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.Stack(.horizontal) {
            PDF.Stack {
                PDF.Text("Top")
                PDF.Text("Bottom")
            }
            PDF.Text("Side")
        }

        PDF.Stack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }
}
