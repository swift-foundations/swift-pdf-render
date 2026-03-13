// PDF Rendering Performance Tests.swift

import Testing
import PDF_Rendering_Test_Support
@testable import PDF_Rendering
import PDF_Standard

extension PDF {
    #Tests
}

// MARK: - Text Rendering

extension PDF.Test.Performance {

    @Test(.timed(iterations: 100, warmup: 10))
    func `render short text`() {
        var context = createContext()
        let text = PDF.Text("Hello World")
        PDF.Text._render(text, context: &context)
    }

    @Test(.timed(iterations: 100, warmup: 10))
    func `render medium text`() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet. ", count: 4)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    @Test(.timed(iterations: 50, warmup: 5))
    func `render long text`() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 18)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    @Test(.timed(iterations: 10, warmup: 2))
    func `render very long text`() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore. ", count: 100)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    // MARK: - Text.Run Encoding

    @Test(.timed(iterations: 1000, warmup: 100))
    func `Text.Run encoding short`() {
        let _ = PDF.Context.Text.Run(
            text: "Hello World",
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    @Test(.timed(iterations: 500, warmup: 50))
    func `Text.Run encoding medium`() {
        let content = String(repeating: "Lorem ipsum dolor sit amet. ", count: 4)
        let _ = PDF.Context.Text.Run(
            text: content,
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    @Test(.timed(iterations: 100, warmup: 10))
    func `Text.Run encoding long`() {
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 18)
        let _ = PDF.Context.Text.Run(
            text: content,
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    // MARK: - Document Generation

    @Test(.timed(iterations: 100, warmup: 10))
    func `document with 1 text element`() {
        let doc = PDF.Document {
            PDF.Text("Hello, World!")
        }
        let _ = [UInt8](doc)
    }

    @Test(.timed(iterations: 50, warmup: 5))
    func `document with 10 text elements`() {
        let doc = PDF.Document {
            for i in 0..<10 {
                PDF.Text("This is paragraph \(i) with some content.")
            }
        }
        let _ = [UInt8](doc)
    }

    @Test(.timed(iterations: 10, warmup: 2))
    func `document with 100 text elements`() {
        let doc = PDF.Document {
            for i in 0..<100 {
                PDF.Text("This is paragraph \(i) with some content to make it longer.")
            }
        }
        let _ = [UInt8](doc)
    }

    // MARK: - Throughput

    @Test(.timed(iterations: 500, warmup: 50))
    func `throughput single document with 18 paragraphs`() {
        let doc = PDF.Document {
            PDF.Text("Document")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
            PDF.Text("This is a test paragraph with some content.")
        }
        let _ = [UInt8](doc)
    }

    // MARK: - Large Document (HexaPDF Comparison)

    @Test(.timed(iterations: 5, warmup: 2))
    func `large document HexaPDF comparison`() {
        let paragraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. "
        let fullText = String(repeating: paragraph, count: 3700)
        let doc = PDF.Document {
            PDF.Text(fullText)
        }
        let _ = [UInt8](doc)
    }

    // MARK: - Text.Run Rendering

    @Test(.timed(iterations: 100, warmup: 10))
    func `render 10 runs`() {
        let runs = createRuns(count: 10)
        var context = createContext()
        PDF.Context.Text.Run.renderRuns(runs, context: &context)
    }

    @Test(.timed(iterations: 20, warmup: 5))
    func `render 100 runs`() {
        let runs = createRuns(count: 100)
        var context = createContext()
        PDF.Context.Text.Run.renderRuns(runs, context: &context)
    }

    @Test(.timed(iterations: 5, warmup: 2))
    func `render 500 runs`() {
        let runs = createRuns(count: 500)
        var context = createContext()
        PDF.Context.Text.Run.renderRuns(runs, context: &context)
    }
}

// MARK: - Helpers

private func createContext() -> PDF.Context {
    PDF.Context(
        mediaBox: .letter,
        margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
    )
}

private func createRuns(count: Int) -> [PDF.Context.Text.Run] {
    (0..<count).map { i in
        PDF.Context.Text.Run(
            text: "This is paragraph \(i) with some content to make it realistic.",
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }
}
