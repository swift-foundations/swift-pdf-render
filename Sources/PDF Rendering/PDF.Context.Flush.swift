// PDF.Context.Flush.swift
// Verb-as-property accessor for flushing buffered content

import Property_Primitives

extension PDF.Context {
    /// Tag for flush operations.
    public enum Flush {}

    /// Flush operations for buffered content.
    public var flush: Property<Flush, Self> {
        get { Property(self) }
        _modify {
            var property = Property<Flush, Self>(self)
            defer { self = property.base }
            yield &property
        }
    }
}

extension Property where Tag == PDF.Context.Flush, Base == PDF.Context {
    /// Flush accumulated inline runs, rendering them as a wrapped block.
    public mutating func inline() {
        guard !base.inline.runs.isEmpty else { return }
        let runs = base.inline.runs
        base.inline.runs.removeAll(keepingCapacity: true)
        PDF.Context.Text.Run.renderRuns(runs, context: &base)
    }

    /// Flush any open text block.
    ///
    /// Call this before switching to graphics operations (lines, rectangles)
    /// or before finalizing the page.
    public mutating func text() {
        guard base.text.blockOpen else { return }
        base.currentPageBuilder.endText()
        base.text.blockOpen = false
        base.text.font = nil
        base.text.fontSize = nil
        base.text.color = nil
        base.text.position = nil
    }
}
