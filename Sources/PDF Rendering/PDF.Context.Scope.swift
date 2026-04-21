// PDF.Context.Scope.swift
// Snapshot of scoped state for push/pop restoration.

import Layout_Primitives
public import PDF_Standard

extension PDF.Context {
    /// Snapshot of scoped state for push/pop restoration.
    ///
    /// Each `push*` method in the `Render.Context` conformance saves a `Scope`,
    /// and the corresponding `pop*` restores from it. This ensures all scoped state —
    /// typography, layout position, whitespace mode, and link URL — is perfectly
    /// symmetric across push/pop pairs.
    public struct Scope: Sendable {
        public let style: Style.Resolved
        public let llx: PDF.UserSpace.X
        public let preserveWhitespace: Bool
        public let linkURL: String?
    }
}
