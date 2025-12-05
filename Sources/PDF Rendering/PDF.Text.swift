// PDF.Text.swift

public import PDF_Standard

extension PDF {
    /// Text element with automatic line wrapping
    public struct Text:  Sendable {
        public typealias Content = Never
        
        /// The text to render
        public var text: String
        
        /// Font override (uses context font if nil)
        public var font: PDF.Font?
        
        /// Font size override (uses context size if nil)
        public var fontSize: PDF.UserSpace.Unit?
        
        /// Color override (uses context color if nil)
        public var color: PDF.Color?
        
        /// Create a text element
        public init(
            _ text: String,
            font: PDF.Font? = nil,
            fontSize: PDF.UserSpace.Unit? = nil,
            color: PDF.Color? = nil
        ) {
            self.text = text
            self.font = font
            self.fontSize = fontSize
            self.color = color
        }
    }
}
