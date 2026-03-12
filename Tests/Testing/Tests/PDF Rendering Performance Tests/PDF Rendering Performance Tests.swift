// PDF Rendering Performance Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

@Suite(.serialized)
struct `PDF Rendering - Performance` {

    // MARK: - Text Rendering

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

    @Test
    func `throughput over 5 seconds`() {
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

        print("Throughput: \(Int(throughput)) docs/sec (\(count) in \(String(format: "%.2f", seconds))s)")
    }

    // MARK: - Large Document (HexaPDF Comparison)

    /// Benchmark comparable to HexaPDF's raw_text benchmark using ~700,000 characters.
    @Test
    func `large document HexaPDF comparison`() {
        let paragraph = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris. "
        let fullText = String(repeating: paragraph, count: 3700)
        let charCount = fullText.count
        let wordCount = fullText.split(separator: " ").count

        print("Large Document Benchmark")
        print("   Characters: \(charCount)")
        print("   Words: ~\(wordCount)")

        // Warm up
        for _ in 0..<2 {
            let doc = PDF.Document {
                PDF.Text(fullText)
            }
            let _ = [UInt8](doc)
        }

        // Timed runs
        var times: [Double] = []
        for _ in 0..<5 {
            let start = ContinuousClock.now
            let doc = PDF.Document {
                PDF.Text(fullText)
            }
            let _ = [UInt8](doc)
            let elapsed = ContinuousClock.now - start
            let ms = Double(elapsed.components.seconds) * 1000 + Double(elapsed.components.attoseconds) / 1e15
            times.append(ms)
        }

        let avgTime = times.reduce(0, +) / Double(times.count)
        let minTime = times.min() ?? 0
        let charsPerSec = Double(charCount) / (avgTime / 1000)

        print("   Min time: \(String(format: "%.0f", minTime))ms")
        print("   Avg time: \(String(format: "%.0f", avgTime))ms")
        print("   Chars/sec: \(String(format: "%.0f", charsPerSec))")
        print("")
        print("   Comparison (HexaPDF benchmark 2025-01-04):")
        print("   - ReportLab/C: 256ms")
        print("   - Prawn: 308ms")
        print("   - fpdf2: 347ms")
        print("   - HexaPDF: 377ms")
        print("   - jPDFWriter: 391ms")
        print("   - PDFKit: 840ms")
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
}
