//
//  File.swift
//  swift-pdf-rendering
//
//  Created by Coen ten Thije Boonkkamp on 05/12/2025.
//

extension PDF.Context {
    /// The output of finalizing a rendering context.
    ///
    /// This is a rendering-library construct (not an ISO 32000 type) representing
    /// the intermediate state between rendering and page assembly:
    /// `View → Context → Output → [Page] → Document`
    public struct Output: Sendable {
        public let contentStreams: [ISO_32000.ContentStream]
        public let annotations: [[PDF.Annotation]]
        
        public init(
            contentStreams: [ISO_32000.ContentStream],
            annotations: [[PDF.Annotation]]
        ) {
            self.contentStreams = contentStreams
            self.annotations = annotations
        }
    }
}
