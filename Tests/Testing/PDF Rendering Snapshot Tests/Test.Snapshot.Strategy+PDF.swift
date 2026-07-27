//
//  Test.Snapshot.Strategy+PDF.swift
//  swift-pdf-rendering
//

import Binary_Serializable_Primitives
import Byte_Primitive
import PDF_Rendering_Test_Support
import Test_Snapshot_Primitives

extension Test.Snapshot.Strategy where Value == PDF.Document, Format == [Byte] {
    /// Binary PDF snapshot strategy.
    ///
    /// Serializes `PDF.Document` to bytes via `Binary.Serializable`,
    /// producing `.pdf` files for visual inspection and byte-identical
    /// regression comparison.
    static var pdf: Self {
        Test.Snapshot.Strategy<[Byte], [Byte]>(pathExtension: "pdf", diffing: .data)
            .pullback { (doc: PDF.Document) -> [Byte] in [Byte](doc) }
    }
}
