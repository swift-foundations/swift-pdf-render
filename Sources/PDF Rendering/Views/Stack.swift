// Stack.swift
// Stack layout types.

public import PDF_Standard

public enum Layout {
    
    /// Stack layout namespace
    public enum Stack<StackContent> {
        case vertical(Vertical)
        case horizontal(Horizontal)
    }
}

extension Layout.Stack: Sendable where StackContent: Sendable {}
extension Layout.Stack: Equatable where StackContent: Equatable {}
extension Layout.Stack: Hashable where StackContent: Hashable {}
extension Layout.Stack: Codable where StackContent: Codable {}

extension Layout.Stack {
    /// Horizontal stack layout
    ///
    /// Arranges child views horizontally with specified spacing.
    public struct Horizontal {
        /// Spacing between elements in points
        public var spacing: PDF.UserSpace.Unit
        
        /// Child content
        public var content: StackContent

    }
}

extension Layout.Stack.Horizontal: Sendable where StackContent: Sendable {}
extension Layout.Stack.Horizontal: Codable where StackContent: Codable {}
extension Layout.Stack.Horizontal: Equatable where StackContent: Equatable {}
extension Layout.Stack.Horizontal: Hashable where StackContent: Hashable {}

extension Layout.Stack {
    /// Vertical stack layout
    ///
    /// Arranges child views vertically with specified spacing.
    public struct Vertical {
        /// Spacing between elements in points
        public var spacing: PDF.UserSpace.Unit

        /// Child content
        public var content: StackContent
    }
}

extension Layout.Stack.Vertical: Sendable where StackContent: Sendable {}
extension Layout.Stack.Vertical: Codable where StackContent: Codable {}
extension Layout.Stack.Vertical: Equatable where StackContent: Equatable {}
extension Layout.Stack.Vertical: Hashable where StackContent: Hashable {}
