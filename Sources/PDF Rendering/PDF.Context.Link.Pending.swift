import PDF_Standard

extension PDF.Context.Link {

    public struct Pending: Sendable, Equatable {

        public let targetId: String

        public let pageNumber: Int

        public let bounds: PDF.UserSpace.Rectangle

        public init(targetId: String, pageNumber: Int, bounds: PDF.UserSpace.Rectangle) {
            self.targetId = targetId
            self.pageNumber = pageNumber
            self.bounds = bounds
        }
    }
}
