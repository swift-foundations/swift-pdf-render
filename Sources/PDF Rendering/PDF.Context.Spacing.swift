// PDF.Context.Spacing.swift
// Stack spacing state.

import PDF_Standard

extension PDF.Context {
    /// Vertical and horizontal stack spacing.
    public struct Spacing: Sendable, Equatable {
        /// Spacing between elements in a VStack.
        public var vertical: PDF.UserSpace.Height?
        /// Spacing between elements in an HStack.
        public var horizontal: PDF.UserSpace.Width?
        public init() {}
    }
}

extension PDF.Context.Spacing {
    /// Whether horizontal layout mode is active.
    public var isHorizontal: Bool { horizontal != nil }
}
