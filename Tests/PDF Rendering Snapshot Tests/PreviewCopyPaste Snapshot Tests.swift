//
//  PreviewCopyPaste Snapshot Tests.swift
//  swift-pdf-rendering
//

import Testing
import Tests_Inline_Snapshot
import Test_Snapshot_Primitives
import PDF_Rendering_Test_Support

@Suite
struct PreviewCopyPasteSnapshotTests {
    @Suite struct Snapshot {}
}

// MARK: - Snapshot

extension PreviewCopyPasteSnapshotTests.Snapshot {
    @Test
    func `space bytes in content stream`() {
        let document = PDF.Document(
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

        snapshot(as: .pdf, named: "preview-space-check") { document }
    }

    @Test
    func `paragraph wrapping`() {
        let document = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Paragraph Wrapping Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text("The quick brown fox jumps over the lazy dog. This sentence wraps.")
        }

        snapshot(as: .pdf, named: "preview-paragraph-wrapping") { document }
    }

    @Test
    func `multiple words emission`() {
        let document = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Multiple Words Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text("certain confidential and proprietary")
        }

        snapshot(as: .pdf, named: "preview-multiple-words") { document }
    }

    @Test
    func `forced line wrapping`() {
        let document = PDF.Document(
            configuration: .init(
                margins: PDF.UserSpace.EdgeInsets(top: 72, leading: 220, bottom: 72, trailing: 220),
                version: .v2_0,
                info: .init(
                    title: "Forced Wrapping Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.Text("The quick brown fox jumps over the lazy dog.")
        }

        snapshot(as: .pdf, named: "preview-forced-wrapping") { document }
    }
}
