// PDF.Context.Link.Pending.swift
// Pending internal link for post-render resolution.

import PDF_Standard

extension PDF.Context.Link {
    /// A pending internal link that needs to be resolved.
    public struct Pending: Sendable, Equatable {
        /// The target anchor id (without #).
        public let targetId: String
        /// Page number where the link is (1-indexed).
        public let pageNumber: Int
        /// Bounds of the link annotation.
        public let bounds: PDF.UserSpace.Rectangle

        public init(targetId: String, pageNumber: Int, bounds: PDF.UserSpace.Rectangle) {
            self.targetId = targetId
            self.pageNumber = pageNumber
            self.bounds = bounds
        }
    }
}
