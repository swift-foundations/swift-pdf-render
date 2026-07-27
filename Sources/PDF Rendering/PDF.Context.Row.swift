// PDF.Context.Row.swift
// Horizontal row tracking state.

import PDF_Standard

extension PDF.Context {
    /// Tracking state for the current horizontal row.
    public struct Row: Sendable, Equatable {
        /// X position before last element rendered.
        internal var lastX: PDF.UserSpace.X?
        /// Starting Y position for current horizontal row.
        internal var startY: PDF.UserSpace.Y?
        /// Maximum Y reached in current horizontal row.
        internal var maxY: PDF.UserSpace.Y?
        public init() {}
    }
}
