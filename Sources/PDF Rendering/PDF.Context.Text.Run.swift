import ASCII
public import Byte_Primitives
public import PDF_Standard

extension PDF.Context.Text {

    public struct Run: Sendable {

        public let bytes: [Byte]

        public let font: PDF.Font

        public let fontSize: PDF.UserSpace.Size<1>

        public let color: PDF.Color

        public let textDecoration: PDF.Annotation.TextMarkup.Kind?

        public let verticalOffset: PDF.UserSpace.Height

        public let linkURL: String?

        public let internalLinkId: String?

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

            self.bytes = [Byte](winAnsi: text, withFallback: true, preservingControlChars: true)
            self.font = font
            self.fontSize = fontSize
            self.color = color
            self.textDecoration = textDecoration
            self.verticalOffset = verticalOffset
            self.linkURL = linkURL
            self.internalLinkId = internalLinkId
        }

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
    }
}

extension PDF.Context.Text.Run {

    public static func runsWithSymbolSupport(
        text: String,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        color: PDF.Color,
        textDecoration: PDF.Annotation.TextMarkup.Kind? = .none,
        verticalOffset: PDF.UserSpace.Height = .init(0),
        linkURL: String? = nil,
        internalLinkId: String? = nil
    ) -> [Self] {
        var runs: [Self] = []
        var currentWinAnsiBytes: [Byte] = []
        var currentDingbatsBytes: [Byte] = []

        func flushWinAnsi() {
            guard !currentWinAnsiBytes.isEmpty else { return }
            runs.append(
                Self(
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
                Self(
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

            if value < 0x20 {
                flushDingbats()
                currentWinAnsiBytes.append(Byte(UInt8(value)))
            }

            else if let byte = ISO_32000.WinAnsiEncoding.encode(scalar) {
                flushDingbats()
                currentWinAnsiBytes.append(byte)
            }

            else if let byte = ISO_32000.ZapfDingbatsEncoding.encode(scalar) {
                flushWinAnsi()
                currentDingbatsBytes.append(byte)
            }

            else if let fallback = ISO_32000.unicodeFallbackMap[value] {
                flushDingbats()
                currentWinAnsiBytes.append(contentsOf: fallback)
            } else {
                flushDingbats()
                currentWinAnsiBytes.append(0x3F)
            }
        }

        flushWinAnsi()
        flushDingbats()

        return runs
    }
}
