// PDF.View Tests.swift

import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.View Tests` {

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
            availableHeight: 700,
            mediaBox: .letter
        )

        let view = TwoLines()
        TwoLines._render(view, context: &context)

        // Content should have been written to the content stream
        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Views emit to context content stream`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        // Render a simple text view
        let view = PDF.Text("Hello, World!")
        PDF.Text._render(view, context: &context)

        // Content stream should have data
        #expect(!context.currentPageBuilder.data.isEmpty)
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
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.VStack {
            PDF.Text("Single")
        }

        PDF.VStack._render(stack, context: &context)

        // Content stream should have data
        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Builds multiple views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let stack = PDF.VStack {
            PDF.Text("One")
            PDF.Text("Two")
            PDF.Text("Three")
        }

        PDF.VStack._render(stack, context: &context)

        // Y should have advanced for 3 lines
        #expect(context.layoutBox.lly > 72)
        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Handles optional views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let includeOptional = true

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        PDF.VStack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Handles missing optional views`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let includeOptional = false

        let stack = PDF.VStack {
            PDF.Text("Always")
            if includeOptional {
                PDF.Text("Sometimes")
            }
        }

        PDF.VStack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Handles if-else`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let useFirst = true

        let stack1 = PDF.VStack {
            if useFirst {
                PDF.Text("First")
            } else {
                PDF.Text("Second")
            }
        }

        PDF.VStack._render(stack1, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Handles for loops`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 400,
            availableHeight: 700,
            mediaBox: .letter
        )

        let items = ["A", "B", "C", "D", "E"]

        let stack = PDF.VStack {
            for item in items {
                PDF.Text(item)
            }
        }

        PDF.VStack._render(stack, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }
}
