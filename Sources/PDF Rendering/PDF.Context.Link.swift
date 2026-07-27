// PDF.Context.Link.swift
// Link annotation state.

import PDF_Standard

extension PDF.Context {
    /// State for link annotations and pending internal links.
    public struct Link: Sendable, Equatable {
        /// Pending internal links to be resolved after rendering.
        public var pending: [Pending] = []
        /// Current link URL for text runs created during pushLink/popLink scope.
        internal var url: String?
        public init() {}
    }
}
