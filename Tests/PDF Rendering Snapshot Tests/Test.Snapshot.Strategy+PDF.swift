//
//  Test.Snapshot.Strategy+PDF.swift
//  swift-pdf-rendering
//

import PDF_Rendering_Test_Support
import Test_Snapshot_Primitives

extension Test.Snapshot.Strategy where Value == PDF.Document, Format == [UInt8] {
    /// Binary PDF snapshot strategy.
    ///
    /// Serializes `PDF.Document` to bytes via `Binary.Serializable`,
    /// producing `.pdf` files for visual inspection and byte-identical
    /// regression comparison.
    static var pdf: Self {
        Test.Snapshot.Strategy<[UInt8], [UInt8]>(pathExtension: "pdf", diffing: .data)
            .pullback { (doc: PDF.Document) -> [UInt8] in [UInt8](doc) }
    }
}
