// PDF.Stack.swift
// Stack layout namespace.

public import PDF_Standard

extension PDF {
    /// Stack layout namespace
    public enum Stack {}
}

// MARK: - Typealiases

extension PDF {
    /// Vertical stack layout
    public typealias VStack<C: PDF.View> = Stack.Vertical<C> where C: Sendable

    /// Horizontal stack layout
    public typealias HStack<C: PDF.View> = Stack.Horizontal<C> where C: Sendable
}
