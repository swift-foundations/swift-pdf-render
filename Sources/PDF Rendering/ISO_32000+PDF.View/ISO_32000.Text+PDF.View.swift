import Byte_Primitives
import Layout_Primitives
import PDF_Standard

extension ISO_32000.Text: PDF.View {

    public var body: Never {
        fatalError("PDF.Text is a leaf view")
    }

    public static func _render(_ text: Self, context: inout PDF.Context) {

        let font = text.state.font.flatMap { context.fonts[$0.name] } ?? context.style.font
        let fontSize = text.state.fontSize ?? context.style.fontSize

        if context.spacing.isHorizontal {
            _renderHorizontal(text, font: font, fontSize: fontSize, context: &context)
        } else {
            _renderVertical(text, font: font, fontSize: fontSize, context: &context)
        }
    }

    private static func _renderVertical(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {

        let lines = wrapBytes(
            text.content,
            font: font,
            size: fontSize,
            maxWidth: context.layout.box.width
        )

        for line in lines {

            context.page.ensure(height: context.style.line.height)

            let baselineY: PDF.UserSpace.Y =
                context.layout.box.lly + font.metrics.ascender(atSize: fontSize)

            context.emit.text(
                line,
                at: PDF.UserSpace.Coordinate(x: context.layout.box.llx, y: baselineY),
                font: font,
                size: fontSize,
                color: context.style.color
            )

            context.advance.line()
        }
    }

    private static func _renderHorizontal(
        _ text: Self,
        font: PDF.Font,
        fontSize: PDF.UserSpace.Size<1>,
        context: inout PDF.Context
    ) {

        context.page.ensure(height: context.style.line.height)

        let textWidth = font.winAnsi.width(of: text.content, atSize: fontSize)

        let baselineY = context.layout.box.lly + font.metrics.ascender(atSize: fontSize)

        context.emit.text(
            text.content,
            at: PDF.UserSpace.Coordinate(x: context.layout.box.llx, y: baselineY),
            font: font,
            size: fontSize,
            color: context.style.color
        )

        context.advance.x(textWidth)
        context.advance.line()
    }

    private static func wrapBytes(
        _ bytes: [Byte],
        font: PDF.Font,
        size: PDF.UserSpace.Size<1>,
        maxWidth: PDF.UserSpace.Width
    ) -> [[Byte]] {
        guard !bytes.isEmpty else { return [[]] }

        let spaceByte = Byte(UInt8.ascii.space)

        let spaceWidth = font.winAnsi.width(of: [spaceByte], atSize: size)

        var lines: [[Byte]] = []
        var currentLine: [Byte] = []
        var currentLineWidth: PDF.UserSpace.Width = .zero
        var currentWord: [Byte] = []

        currentLine.reserveCapacity(256)
        currentWord.reserveCapacity(64)

        func processWord() {
            guard !currentWord.isEmpty else { return }

            let wordWidth = font.winAnsi.width(of: currentWord, atSize: size)

            if currentLine.isEmpty {

                if wordWidth > maxWidth {

                    lines.append(currentWord)
                } else {
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            } else {

                let potentialWidth = currentLineWidth + spaceWidth + wordWidth
                if potentialWidth <= maxWidth {
                    currentLine.append(spaceByte)
                    currentLine.append(contentsOf: currentWord)
                    currentLineWidth = potentialWidth
                } else {

                    currentLine.append(spaceByte)
                    lines.append(currentLine)
                    currentLine = currentWord
                    currentLineWidth = wordWidth
                }
            }
            currentWord = []
        }

        for byte in bytes {
            if byte == spaceByte {
                processWord()
            } else {
                currentWord.append(byte)
            }
        }

        processWord()

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [[]] : lines
    }
}
