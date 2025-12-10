// PDF.ForEach.swift
// ForEach for PDF rendering, using Rendering._Array internally.

public import Rendering

extension PDF {
    /// A component that creates PDF content for each element in a collection.
    ///
    /// `PDF.ForEach` provides a way to generate content by iterating over
    /// a collection and applying a transform to each element.
    ///
    /// Example:
    /// ```swift
    /// let headers = ["Product", "Units", "Revenue"]
    ///
    /// PDF.ForEach(headers) { header in
    ///     PDF.Table.Header.Cell(scope: .column) {
    ///         Pair(
    ///             PDF.Rectangle(width: 100, height: 24, fill: .gray(0.9)),
    ///             PDF.Text(header)
    ///         )
    ///     }
    /// }
    /// ```
    public struct ForEach<Content: PDF.View> {
        /// The array of content generated from the collection.
        public let content: Rendering._Array<Content>

        /// Creates a new component that generates content for each element in a collection.
        ///
        /// - Parameters:
        ///   - data: The collection to iterate over.
        ///   - content: A closure that transforms each element of the collection into content.
        public init<Data: RandomAccessCollection>(
            _ data: Data,
            @PDF.Builder content: (Data.Element) -> Content
        ) {
            self.content = PDF.Builder.buildArray(data.map(content))
        }
    }
}

extension PDF.ForEach: PDF.View {
    /// The body of this component, which is the array of content.
    public var body: Rendering._Array<Content> {
        content
    }
}

extension PDF.ForEach: Sendable where Content: Sendable {}
extension PDF.ForEach: Hashable where Content: Hashable {}
extension PDF.ForEach: Equatable where Content: Equatable {}
