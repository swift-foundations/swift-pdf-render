// Performance Tests.swift

import Testing
import TestingPerformance
import PDF_Standard
@testable import PDF_Rendering

extension Tag {
    @Tag static var performance: Self
}

@Suite("Performance Tests", .serialized, .tags(.performance))
struct PerformanceTests {

    // MARK: - Text Rendering Benchmarks

    @Test("Render short text (10 chars)", .timed(iterations: 100, warmup: 10))
    func shortText() {
        var context = createContext()
        let text = PDF.Text("Hello World")
        PDF.Text._render(text, context: &context)
    }

    @Test("Render medium text (100 chars)", .timed(iterations: 100, warmup: 10))
    func mediumText() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet. ", count: 4)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    @Test("Render long text (1000 chars)", .timed(iterations: 50, warmup: 5))
    func longText() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 18)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    @Test("Render very long text (10000 chars)", .timed(iterations: 10, warmup: 2))
    func veryLongText() {
        var context = createContext()
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore. ", count: 100)
        let text = PDF.Text(content)
        PDF.Text._render(text, context: &context)
    }

    // MARK: - TextRun Creation Benchmarks (WinAnsi encoding)

    @Test("TextRun encoding short (10 chars)", .timed(iterations: 1000, warmup: 100))
    func textRunShort() {
        let _ = PDF.Context.TextRun(
            text: "Hello World",
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    @Test("TextRun encoding medium (100 chars)", .timed(iterations: 500, warmup: 50))
    func textRunMedium() {
        let content = String(repeating: "Lorem ipsum dolor sit amet. ", count: 4)
        let _ = PDF.Context.TextRun(
            text: content,
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    @Test("TextRun encoding long (1000 chars)", .timed(iterations: 100, warmup: 10))
    func textRunLong() {
        let content = String(repeating: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", count: 18)
        let _ = PDF.Context.TextRun(
            text: content,
            font: .helvetica,
            fontSize: 12,
            color: .black
        )
    }

    // MARK: - Document Generation Benchmarks

    @Test("Document with 1 text element", .timed(iterations: 100, warmup: 10))
    func documentSingle() {
        let doc = PDF.Document {
            PDF.Text("Hello, World!")
        }
        let _ = [UInt8](doc)
    }

    @Test("Document with 10 text elements", .timed(iterations: 50, warmup: 5))
    func document10() {
        let doc = PDF.Document {
            for i in 0..<10 {
                PDF.Text("This is paragraph \(i) with some content.")
            }
        }
        let _ = [UInt8](doc)
    }

    @Test("Document with 100 text elements", .timed(iterations: 10, warmup: 2))
    func document100() {
        let doc = PDF.Document {
            for i in 0..<100 {
                PDF.Text("This is paragraph \(i) with some content to make it longer.")
            }
        }
        let _ = [UInt8](doc)
    }

    // MARK: - Throughput Test

    @Test("Throughput (5 second run)")
    func throughput() {
        let duration: Duration = .seconds(5)
        let start = ContinuousClock.now
        var count = 0

        while ContinuousClock.now - start < duration {
            let doc = PDF.Document {
                PDF.Text("Document \(count)")
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
            count += 1
        }

        let elapsed = ContinuousClock.now - start
        let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        let throughput = Double(count) / seconds

        print("📊 Throughput: \(Int(throughput)) docs/sec (\(count) in \(String(format: "%.2f", seconds))s)")
    }

    // MARK: - TextRun Rendering Benchmarks

    @Test("Render 10 runs", .timed(iterations: 100, warmup: 10))
    func render10Runs() {
        let runs = createRuns(count: 10)
        var context = createContext()
        PDF.Context.TextRun.renderRuns(runs, context: &context)
    }

    @Test("Render 100 runs", .timed(iterations: 20, warmup: 5))
    func render100Runs() {
        let runs = createRuns(count: 100)
        var context = createContext()
        PDF.Context.TextRun.renderRuns(runs, context: &context)
    }

    @Test("Render 500 runs", .timed(iterations: 5, warmup: 2))
    func render500Runs() {
        let runs = createRuns(count: 500)
        var context = createContext()
        PDF.Context.TextRun.renderRuns(runs, context: &context)
    }

    // MARK: - Helpers

    private func createContext() -> PDF.Context {
        PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
        )
    }

    private func createRuns(count: Int) -> [PDF.Context.TextRun] {
        (0..<count).map { i in
            PDF.Context.TextRun(
                text: "This is paragraph \(i) with some content to make it realistic.",
                font: .helvetica,
                fontSize: 12,
                color: .black
            )
        }
    }
}
