//
//  PDF.Context.ListType.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

// MARK: - List Type

extension PDF.Context {
    /// Type of list being rendered.
    public enum ListType: Sendable {
        case unordered
        case ordered(startNumber: Int)
    }
}
