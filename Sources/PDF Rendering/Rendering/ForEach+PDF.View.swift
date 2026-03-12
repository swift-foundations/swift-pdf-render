// PDF.ForEach.swift
// ForEach for PDF rendering, using Rendering._Array internally.

public import Rendering_Primitives

extension Rendering.ForEach: PDF.View where Content: PDF.View {
    /// The body of this component, which is the array of content.
    public var body: Rendering._Array<Content> {
        content
    }
}
