import Binary_Serializable_Primitives
import Foundation
import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `Preview Copy-Paste Tests` {

    @Test
    func `Verify space bytes in content stream`() throws {
        let pdfDocument = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Space Check Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text("hello world")
        }

        let pdfBytes = [UInt8](pdfDocument)

        let pdfString = String(decoding: pdfBytes, as: UTF8.self)

        let hasLiteralSpace = pdfString.contains("(hello world)")
        let hasSeparateWords = pdfString.contains("(hello)") && pdfString.contains("(world)")

        print("PDF contains '(hello world)' with literal space: \(hasLiteralSpace)")
        print("PDF contains separate '(hello)' and '(world)': \(hasSeparateWords)")

        let path = try PDFOutput.write(pdfBytes, name: "preview-test-space-check")
        print("Test PDF written to: \(path)")

        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = pdfString[streamStart.upperBound..<streamEnd.lowerBound]
            print("\n--- Content Stream ---")
            print(stream.prefix(500))
            print("--- End ---\n")
        }
    }

    @Test
    func `Verify paragraph wrapping`() throws {
        let testParagraph = "The quick brown fox jumps over the lazy dog. This sentence wraps."

        let pdfDocument = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Paragraph Wrapping Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text(testParagraph)
        }

        let pdfBytes = [UInt8](pdfDocument)
        let path = try PDFOutput.write(pdfBytes, name: "preview-test-paragraph")
        print("Paragraph test PDF written to: \(path)")

        let pdfString = String(decoding: pdfBytes, as: UTF8.self)
        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])

            let tjCount = stream.components(separatedBy: " Tj").count - 1
            print("Number of Tj operators: \(tjCount)")

            let hasSpaceInStrings = stream.contains("( ") || stream.contains(" )")
            print("Has spaces in text strings: \(hasSpaceInStrings)")
        }
    }

    @Test
    func `Multiple words emission patterns`() throws {

        let shortPhrase = "certain confidential and proprietary"

        let pdfDocument = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Multiple Words Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text(shortPhrase)
        }

        let pdfBytes = [UInt8](pdfDocument)
        let path = try PDFOutput.write(pdfBytes, name: "preview-test-multiword")
        print("Multiple words test PDF written to: \(path)")

        let pdfString = String(decoding: pdfBytes, as: UTF8.self)

        let wordsInSingleTj = pdfString.contains("(certain confidential and proprietary)")
        let wordsWithSpaces = pdfString.contains("certain") && pdfString.contains("confidential")

        print("All words in single Tj: \(wordsInSingleTj)")
        print("Contains individual words: \(wordsWithSpaces)")

        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])
            print("\n--- Content Stream ---")
            print(stream)
            print("--- End ---\n")

            let lines = stream.split(separator: "\n")
            let tjLines = lines.filter { $0.contains("Tj") }
            print("Tj operations found: \(tjLines.count)")
            for line in tjLines {
                print("  \(line)")
            }
        }
    }

    @Test
    func `Forced line wrapping`() throws {

        let testText = "The quick brown fox jumps over the lazy dog."

        let pdfDocument = PDF.Document(
            configuration: .init(
                margins: PDF.EdgeInsets(top: 72, leading: 220, bottom: 72, trailing: 220),
                version: .v2_0,
                info: .init(
                    title: "Forced Wrapping Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text(testText)
        }

        let pdfBytes = [UInt8](pdfDocument)
        let path = try PDFOutput.write(pdfBytes, name: "preview-test-forced-wrap")
        print("Forced wrap test PDF written to: \(path)")

        let pdfString = String(decoding: pdfBytes, as: UTF8.self)

        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])
            print("\n--- Content Stream (forced wrap) ---")
            print(stream)
            print("--- End ---\n")

            let lines = stream.split(separator: "\n")
            let tjLines = lines.filter { $0.contains("Tj") }
            print("Tj operations found: \(tjLines.count)")
            for line in tjLines {
                print("  \(line)")
            }

            let tdLines = lines.filter { $0.contains("Td") }
            print("Td operations found: \(tdLines.count)")
            for line in tdLines {
                print("  \(line)")
            }
        }
    }
}
