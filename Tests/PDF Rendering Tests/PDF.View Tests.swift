// PDF.View Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

@Suite
struct `PDF.View Tests` {

    // MARK: - Protocol Conformance

    @Test
    func `PDF.Content conforms to View`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        // ContentStream is a leaf view that returns itself
        let content = PDF.Content()
        let rendered = PDF.Content._render(content, context: &context)

        #expect(rendered.data.isEmpty)
    }

    // MARK: - Custom View

    @Test
    func `Custom view delegates to body`() {
        struct TwoLines: PDF.View {
            var body: some PDF.View {
                PDF.VStack {
                    PDF.Text("Line 1")
                    PDF.Text("Line 2")
                }
            }
        }

        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let view = TwoLines()
        _ = PDF.render(view, context: &context)

        // Operations should be added to context
        let textOps = context.currentPageOperations.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 2)
    }

    @Test
    func `Views add operations to context`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        // Render a simple text view
        let view = PDF.Text("Hello, World!")
        _ = PDF.render(view, context: &context)

        // Operations should be in context
        #expect(!context.currentPageOperations.isEmpty)
    }
}

// MARK: - Builder Tests

@Suite
struct `PDF.Builder Tests` {

    @Test
    func `Builds single view`() {
        let stack = PDF.VStack {
            PDF.Text("Single")
        }

        #expect(stack.children.count == 1)
    }

    @Test
    func `Builds multiple views`() {
        let stack = PDF.VStack {
            PDF.Text("One")
            PDF.Text("Two")
            PDF.Text("Three")
        }

        #expect(stack.children.count == 3)
    }

    @Test
    func `Handles optional views`() {
        let includeOptional = true

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        #expect(stack.children.count == 2)
    }

    @Test
    func `Handles missing optional views`() {
        let includeOptional = false

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        #expect(stack.children.count == 1)
    }

    @Test
    func `Handles if-else`() {
        let useFirst = true

        let stack1 = PDF.VStack {
            if useFirst {
                PDF.Text("First")
            } else {
                PDF.Text("Second")
            }
        }

        #expect(stack1.children.count == 1)
    }

    @Test
    func `Handles for loops`() {
        let items = ["A", "B", "C", "D", "E"]

        let stack = PDF.VStack {
            for item in items {
                PDF.Text(item)
            }
        }

        #expect(stack.children.count == 5)
    }
}
