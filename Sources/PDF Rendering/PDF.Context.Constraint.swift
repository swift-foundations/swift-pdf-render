// PDF.Context.Constraint.swift
// Explicit dimension constraints.

import PDF_Standard

extension PDF.Context {
    /// Explicit width and height constraints.
    public struct Constraint: Sendable, Equatable {
        public var width: PDF.UserSpace.Width?
        public var height: PDF.UserSpace.Height?
        public init() {}
    }
}
