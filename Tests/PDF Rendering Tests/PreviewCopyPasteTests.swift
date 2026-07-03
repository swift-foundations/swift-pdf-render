// PreviewCopyPasteTests.swift
// Tests to understand macOS Preview's copy-paste text extraction behavior

import Binary_Serializable_Primitives
import Foundation
import PDF_Standard
import Testing

@testable import PDF_Rendering

/// Test different text emission strategies to find which produces
/// correct copy-paste behavior in macOS Preview.
@Suite
struct `Preview Copy-Paste Tests` {

    /// Test: Check if spaces are literal 0x20 bytes in the content stream
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

        // Convert to string and search for the text operators
        let pdfString = String(decoding: pdfBytes, as: UTF8.self)

        // Check if we can find "(hello world)" or "(hello) ... (world)" pattern
        let hasLiteralSpace = pdfString.contains("(hello world)")
        let hasSeparateWords = pdfString.contains("(hello)") && pdfString.contains("(world)")

        print("PDF contains '(hello world)' with literal space: \(hasLiteralSpace)")
        print("PDF contains separate '(hello)' and '(world)': \(hasSeparateWords)")

        let path = try PDFOutput.write(pdfBytes, name: "preview-test-space-check")
        print("Test PDF written to: \(path)")

        // Dump content stream for inspection
        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = pdfString[streamStart.upperBound..<streamEnd.lowerBound]
            print("\n--- Content Stream ---")
            print(stream.prefix(500))
            print("--- End ---\n")
        }
    }

    /// Test paragraph wrapping behavior
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

        // Check content stream
        let pdfString = String(decoding: pdfBytes, as: UTF8.self)
        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])

            // Count Tj operators to see how many text show operations
            let tjCount = stream.components(separatedBy: " Tj").count - 1
            print("Number of Tj operators: \(tjCount)")

            // Check for space characters (0x20) in strings
            let hasSpaceInStrings = stream.contains("( ") || stream.contains(" )")
            print("Has spaces in text strings: \(hasSpaceInStrings)")
        }
    }

    /// Test: Multiple words on one line vs separate Tj operators
    @Test
    func `Multiple words emission patterns`() throws {
        // Test short phrase that should fit on one line
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

        // Check what emission pattern is used
        let wordsInSingleTj = pdfString.contains("(certain confidential and proprietary)")
        let wordsWithSpaces = pdfString.contains("certain") && pdfString.contains("confidential")

        print("All words in single Tj: \(wordsInSingleTj)")
        print("Contains individual words: \(wordsWithSpaces)")

        // Extract and display the content stream
        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])
            print("\n--- Content Stream ---")
            print(stream)
            print("--- End ---\n")

            // Find all Tj operations
            let lines = stream.split(separator: "\n")
            let tjLines = lines.filter { $0.contains("Tj") }
            print("Tj operations found: \(tjLines.count)")
            for line in tjLines {
                print("  \(line)")
            }
        }
    }

    /// Test: Force text to wrap across multiple lines
    @Test
    func `Forced line wrapping`() throws {
        // Use very wide margins to force text wrapping (leaves only ~160pt of content width)
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

        // Extract and display the content stream
        if let streamStart = pdfString.range(of: "stream\n"),
            let streamEnd = pdfString.range(of: "\nendstream")
        {
            let stream = String(pdfString[streamStart.upperBound..<streamEnd.lowerBound])
            print("\n--- Content Stream (forced wrap) ---")
            print(stream)
            print("--- End ---\n")

            // Find all Tj operations
            let lines = stream.split(separator: "\n")
            let tjLines = lines.filter { $0.contains("Tj") }
            print("Tj operations found: \(tjLines.count)")
            for line in tjLines {
                print("  \(line)")
            }

            // Find all Td operations (text positioning)
            let tdLines = lines.filter { $0.contains("Td") }
            print("Td operations found: \(tdLines.count)")
            for line in tdLines {
                print("  \(line)")
            }
        }
    }
}
