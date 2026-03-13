// PDF.Context.Padding.swift
// Box model padding state.

import PDF_Standard

extension PDF.Context {
    /// Box model padding (internal spacing within element).
    public struct Padding: Sendable, Equatable {
        public var top: PDF.UserSpace.Height?
        public var right: PDF.UserSpace.Width?
        public var bottom: PDF.UserSpace.Height?
        public var left: PDF.UserSpace.Width?
        public init() {}
    }
}
