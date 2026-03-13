// PDF.Context.Layout.swift
// Layout box and pagination bounds.

import PDF_Standard

extension PDF.Context {
    /// Layout box, initial box, and maximum Y boundary.
    public struct Layout: Sendable, Equatable {
        /// The layout box (position + available size).
        public var box: PDF.UserSpace.Rectangle
        /// Initial layout box (for page reset).
        internal var initial: PDF.UserSpace.Rectangle
        /// Maximum Y position (bottom boundary).
        internal var maxY: PDF.UserSpace.Y
    }
}
