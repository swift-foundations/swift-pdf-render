//
//  PDF.Context.List.Kind.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

// MARK: - List Kind

extension PDF.Context.List {
    /// Type of list being rendered.
    public enum Kind: Sendable {
        case unordered
        case ordered(startNumber: Int)
    }
}
