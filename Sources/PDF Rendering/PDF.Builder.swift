// PDF.Builder.swift
// Uses typed composition primitives from swift-renderable

public import PDF_Standard
public import Render_Primitives

// Re-export Builder from Renderable
public typealias BuilderRaw = Render.Builder

extension PDF {
    /// Result builder for composing PDF views using typed primitives.
    ///
    /// Uses the same `_Tuple`, `_Conditional`, `_Array`, `Empty` primitives
    /// as HTML.Builder for consistent composition patterns.
    public typealias Builder = BuilderRaw
}

// MARK: - Builder extensions for Empty

extension BuilderRaw {
    /// Creates an empty PDF component when no content is provided.
    public static func buildBlock() -> Render.Empty {
        Render.Empty()
    }
}
