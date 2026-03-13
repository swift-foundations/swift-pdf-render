// PDF.Context.Text.State.swift
// Text block batching state for BT/ET blocks.

import PDF_Standard

extension PDF.Context.Text {
    /// State for batching text operations within BT/ET blocks.
    internal struct State: Sendable, Equatable {
        /// Whether we're inside a BT (begin text) block.
        internal var blockOpen: Bool = false
        /// Current font set in the open text block.
        internal var font: PDF.Font? = nil
        /// Current font size set in the open text block.
        internal var fontSize: PDF.UserSpace.Size<1>? = nil
        /// Current fill color set in the open text block.
        internal var color: PDF.Color? = nil
        /// Current text position (PDF coordinates, for relative positioning).
        internal var position: PDF.UserSpace.Coordinate? = nil
        internal init() {}
    }
}
