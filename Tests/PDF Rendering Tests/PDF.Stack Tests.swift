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

        #expect(stack.children.count == 2)
        #expect(stack.spacing == 10)
    }

    @Test
    func `Creates VStack with explicit children`() {
        let stack = PDF.Stack.Vertical(
            spacing: 5,
            children: [PDF.Text("A"), PDF.Text("B")]
        )

        #expect(stack.children.count == 2)
        #expect(stack.spacing == 5)
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

        let content = stack.render(context: &context)

        let textOps = content.operations.filter {
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
        _ = stack.render(context: &context)

        // 2 lines at 12pt + 20pt spacing between = 44pt
        #expect(context.y == startY + 12 + 20 + 12)
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
        _ = stack.render(context: &context)

        // Single line, no spacing added
        #expect(context.y == startY + 12)
    }

    @Test
    func `VStack is aliased as Stack.Vertical`() {
        let _: PDF.VStack = PDF.Stack.Vertical(spacing: 0, children: [])
        let _: PDF.Stack.Vertical = PDF.VStack(spacing: 0, children: [])
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

        #expect(stack.children.count == 2)
        #expect(stack.spacing == 10)
    }

    @Test
    func `Creates HStack with explicit children`() {
        let stack = PDF.Stack.Horizontal(
            spacing: 5,
            children: [PDF.Text("A"), PDF.Text("B")]
        )

        #expect(stack.children.count == 2)
        #expect(stack.spacing == 5)
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

        let content = stack.render(context: &context)

        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 3)
    }

    @Test
    func `Y advances by max child height`() {
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
        _ = stack.render(context: &context)

        // Both are single lines, so max height is one line
        #expect(context.y == startY + 12)
    }

    @Test
    func `HStack is aliased as Stack.Horizontal`() {
        let _: PDF.HStack = PDF.Stack.Horizontal(spacing: 0, children: [])
        let _: PDF.Stack.Horizontal = PDF.HStack(spacing: 0, children: [])
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

        let content = stack.render(context: &context)

        #expect(!content.operations.isEmpty)
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

        let content = stack.render(context: &context)

        #expect(!content.operations.isEmpty)
    }
}
