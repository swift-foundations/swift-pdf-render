// PDF.View Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

@Suite
struct `PDF.View Tests` {

    // MARK: - Protocol Conformance

    @Test
    func `PDF.Content is created empty`() {
        // ContentStream is a raw PDF content container
        let content = PDF.Content()
        #expect(content.data.isEmpty)
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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(view, into: &buffer, context: &context)

        // Operations should be in the buffer
        let textOps = buffer.filter {
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
        var buffer: [PDF.Render.Operation] = []
        PDF.render(view, into: &buffer, context: &context)

        // Operations should be in the buffer
        #expect(!buffer.isEmpty)
    }
}

// MARK: - Builder Tests

@Suite
struct `PDF.Builder Tests` {

    @Test
    func `Builds single view`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.VStack {
            PDF.Text("Single")
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 1)
    }

    @Test
    func `Builds multiple views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let stack = PDF.VStack {
            PDF.Text("One")
            PDF.Text("Two")
            PDF.Text("Three")
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
    func `Handles optional views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let includeOptional = true

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 2)
    }

    @Test
    func `Handles missing optional views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let includeOptional = false

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 1)
    }

    @Test
    func `Handles if-else`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let useFirst = true

        let stack1 = PDF.VStack {
            if useFirst {
                PDF.Text("First")
            } else {
                PDF.Text("Second")
            }
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack1, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 1)
    }

    @Test
    func `Handles for loops`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700
        )

        let items = ["A", "B", "C", "D", "E"]

        let stack = PDF.VStack {
            for item in items {
                PDF.Text(item)
            }
        }

        var buffer: [PDF.Render.Operation] = []
        PDF.render(stack, into: &buffer, context: &context)

        let textOps = buffer.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 5)
    }
}
