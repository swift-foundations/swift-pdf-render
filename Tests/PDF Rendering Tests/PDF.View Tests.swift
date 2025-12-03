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

        let content = PDF.Content(operations: [
            .text(PDF.Content.Text.Operation(
                text: "Hello",
                position: .zero,
                font: .helvetica,
                size: 12,
                color: .black
            ))
        ])

        let rendered = content.render(context: &context)

        #expect(rendered.operations.count == 1)
    }

    @Test
    func `PDF.Content render returns self`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600
        )

        let original = PDF.Content(operations: [
            .text(PDF.Content.Text.Operation(
                text: "Test",
                position: .zero,
                font: .helvetica,
                size: 12,
                color: .black
            ))
        ])

        let rendered = original.render(context: &context)

        #expect(rendered.operations.count == original.operations.count)
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
        let content = view.render(context: &context)

        let textOps = content.operations.filter {
            if case .text = $0 { return true }
            return false
        }

        #expect(textOps.count == 2)
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
