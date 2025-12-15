// PDF.Text Tests.swift

import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.Text Tests` {

    // MARK: - Construction

    @Test
    func `Creates text with content`() {
        let text = PDF.Text("Hello, World!")
        #expect(text.string == "Hello, World!")
    }

    @Test
    func `Creates text with state parameters`() {
        let text = PDF.Text(
            "Custom text",
            state: .init(fontSize: 18)
        )

        #expect(text.string == "Custom text")
        #expect(text.state.fontSize == 18)
    }

    @Test
    func `Optional parameters default to nil or initial values`() {
        let text = PDF.Text("Simple")

        #expect(text.state.font == nil)
        #expect(text.state.fontSize == nil)
        #expect(text.state.characterSpacing == 0)
        #expect(text.state.wordSpacing == 0)
    }

    @Test
    func `Creates text with full state`() {
        var state = PDF.Text.State()
        state.fontSize = 14
        state.characterSpacing = 1
        let text = PDF.Text("Styled text", state: state)

        #expect(text.string == "Styled text")
        #expect(text.state.fontSize == 14)
        #expect(text.state.characterSpacing == 1)
    }

    // MARK: - Single Line Rendering

    @Test
    func `Renders single line text`() {
        var context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
        )

        let text = PDF.Text("Hello, World!")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    @Test
    func `Advances Y after rendering`() {
        var context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
        )
        let startY = context.layoutBox.lly

        let text = PDF.Text("Hello")
        PDF.Text._render(text, context: &context)

        // Y should have advanced
        #expect(context.layoutBox.lly > startY)
    }

    @Test
    func `Uses context font when not specified in state`() {
        var context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
        )
        context.style.font = PDF.Font.courier.bold

        let text = PDF.Text("Hello")
        PDF.Text._render(text, context: &context)

        // Font should be in the fonts used
        #expect(context.currentPageBuilder.fontsUsed.contains(PDF.Font.courier.bold))
    }

    // MARK: - Text Wrapping

    @Test
    func `Wraps long text to multiple lines`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 100,  // Narrow width to force wrapping
            availableHeight: 700,
            mediaBox: .letter
        )

        let text = PDF.Text("This is a longer text that should wrap to multiple lines")
        let startY = context.layoutBox.lly
        PDF.Text._render(text, context: &context)

        // Y should have advanced by more than one line
        let lineHeight = context.style.line.height
        #expect(height(context.layoutBox.lly - startY) > lineHeight)
    }

    @Test
    func `Word that exceeds width gets its own line`() {
        var context = PDF.Context(
            x: 72,
            y: 72,
            availableWidth: 50,  // Very narrow
            availableHeight: 700,
            mediaBox: .letter
        )

        let text = PDF.Text("Supercalifragilisticexpialidocious")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    // MARK: - Empty Text

    @Test
    func `Empty text produces single empty line`() {
        var context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(top: 72, leading: 72, bottom: 72, trailing: 72)
        )

        let text = PDF.Text("")
        PDF.Text._render(text, context: &context)

        #expect(!context.currentPageBuilder.data.isEmpty)
    }

    // MARK: - Byte Storage

    @Test
    func `Stores content as bytes`() {
        let text = PDF.Text("ABC")
        #expect(text.content == [0x41, 0x42, 0x43])  // WinAnsi for "ABC"
    }

    @Test
    func `Creates from raw bytes`() {
        let text = PDF.Text(bytes: [0x48, 0x69])  // "Hi" in ASCII/WinAnsi
        #expect(text.string == "Hi")
    }
}
