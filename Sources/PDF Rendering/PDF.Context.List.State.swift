// PDF.Context.List.State.swift
// List nesting state.

import PDF_Standard

extension PDF.Context.List {
    /// State for tracking nested list context.
    public struct State: Sendable {
        /// Stack of active lists (for nested list support).
        public var stack: [(type: Kind, currentIndex: Int)] = []
        /// Pending list marker to be rendered with the first line of text.
        public var marker: (marker: Marker, x: PDF.UserSpace.X)?
        public init() {}
    }
}

extension PDF.Context.List.State {
    /// Current list nesting depth (0 = not in a list).
    public var depth: Int { stack.count }
}
