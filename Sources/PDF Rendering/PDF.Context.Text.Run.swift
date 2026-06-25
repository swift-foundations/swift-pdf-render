// PDF.Context.Text.Run.swift

import ASCII
public import Byte_Primitives
public import PDF_Standard

extension PDF.Context.Text {
    /// A styled text segment for inline text flow.
    ///
    /// Runs accumulate in the context and are rendered together
    /// when a block element flushes them, enabling proper inline flow
    /// with mixed styling (e.g., "It supports **bold** and *italic* text.").
    public struct Run: Sendable {
        /// The text content as WinAnsi-encoded bytes
        public let bytes: [Byte]

        /// Font for this text segment
        public let font: PDF.Font

        /// Font size in points
        public let fontSize: PDF.UserSpace.Size<1>

        /// Text color
        public let color: PDF.Color

        /// Text decoration (underline, strikethrough, etc.)
        public let textDecoration: PDF.Annotation.TextMarkup.Kind?

        /// Vertical offset for subscript/superscript (positive = up, negative = down)
        public let verticalOffset: PDF.UserSpace.Height

        /// Optional link URL (makes this text a clickable external link)
        public let linkURL: String?

        /// Optional internal link target ID (for #anchor links)
        /// Used to create pending internal links that are resolved after rendering completes.
        public let internalLinkId: String?

        /// Create a text run from a String (encodes to WinAnsi)
        public init(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Height = .init(0),
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            // Encode to WinAnsi, preserving control characters for tokenizer.
            // Control chars (newline, tab, etc.) are handled specially by the tokenizer
            // and must remain as their raw byte values, not be converted to '?'.
            self.bytes = [Byte](winAnsi: text, withFallback: true, preservingControlChars: true)
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create a text run from pre-encoded bytes
        public init(
            bytes: [Byte],
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Height = .init(0),
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) {
            self.bytes = bytes
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

        /// Create text runs from a String, automatically switching to ZapfDingbats for symbols.
        ///
        /// This method scans the text for characters that:
        /// - Can be encoded in WinAnsi -> uses the provided font
        /// - Can be encoded in ZapfDingbats but not WinAnsi -> switches to ZapfDingbats font
        /// - Cannot be encoded in either -> uses the fallback character
        ///
        /// - Parameters:
        ///   - text: The text to convert
        ///   - font: The primary font to use for regular text
        ///   - fontSize: Font size
        ///   - color: Text color
        ///   - textDecoration: Optional text decoration
        ///   - verticalOffset: Vertical offset for sub/superscript
        ///   - linkURL: Optional external link URL
        ///   - internalLinkId: Optional internal link target ID (for #anchor links)
        /// - Returns: Array of Runs, possibly with different fonts
        public static func runsWithSymbolSupport(
            text: String,
            font: PDF.Font,
            fontSize: PDF.UserSpace.Size<1>,
            color: PDF.Color,
            textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
            verticalOffset: PDF.UserSpace.Height = .init(0),
            linkURL: String? = nil,
            internalLinkId: String? = nil
        ) -> [Run] {
            var runs: [Run] = []
            var currentWinAnsiBytes: [Byte] = []
            var currentDingbatsBytes: [Byte] = []

            func flushWinAnsi() {
                guard !currentWinAnsiBytes.isEmpty else { return }
                runs.append(
                    Run(
                        bytes: currentWinAnsiBytes,
                        font: font,
                        fontSize: fontSize,
                        color: color,
                        textDecoration: textDecoration,
                        verticalOffset: verticalOffset,
                        linkURL: linkURL,
                        internalLinkId: internalLinkId
                    )
                )
                currentWinAnsiBytes = []
            }

            func flushDingbats() {
                guard !currentDingbatsBytes.isEmpty else { return }
                runs.append(
                    Run(
                        bytes: currentDingbatsBytes,
                        font: .zapfDingbats,
                        fontSize: fontSize,
                        color: color,
                        textDecoration: textDecoration,
                        verticalOffset: verticalOffset,
                        linkURL: linkURL,
                        internalLinkId: internalLinkId
                    )
                )
                currentDingbatsBytes = []
            }

            for scalar in text.unicodeScalars {
                let value = scalar.value

                // Preserve control characters (0x00-0x1F) as-is for tokenizer
                // This includes newlines (0x0A), tabs (0x09), etc.
                if value < 0x20 {
                    flushDingbats()
                    currentWinAnsiBytes.append(Byte(UInt8(value)))
                }
                // Try WinAnsi first (primary encoding)
                else if let byte = ISO_32000.WinAnsiEncoding.encode(scalar) {
                    flushDingbats()
                    currentWinAnsiBytes.append(byte)
                }
                // Try ZapfDingbats for symbols
                else if let byte = ISO_32000.ZapfDingbatsEncoding.encode(scalar) {
                    flushWinAnsi()
                    currentDingbatsBytes.append(byte)
                }
                // Use fallback from the map, or '?' as last resort
                else if let fallback = ISO_32000.unicodeFallbackMap[value] {
                    flushDingbats()
                    currentWinAnsiBytes.append(contentsOf: fallback)
                } else {
                    flushDingbats()
                    currentWinAnsiBytes.append(0x3F)  // '?'
                }
            }

            // Flush remaining bytes
            flushWinAnsi()
            flushDingbats()

            return runs
        }
    }
}
