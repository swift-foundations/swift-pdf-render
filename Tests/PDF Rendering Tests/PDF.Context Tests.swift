// PDF.Context Tests.swift

import Layout_Primitives
import PDF_Rendering_Test_Support
import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.Context Tests` {

    // MARK: - Construction

    @Test
    func `Creates context with all parameters`() {
        let context = PDF.Context(
            x: 100,
            y: 200,
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter,
            font: .times,
            fontSize: 14,
            color: .blue,
            lineHeight: 1.5
        )

        #expect(context.layout.box.llx == 100)
        #expect(context.layout.box.lly == 200)
        #expect(context.layout.box.width == 400)
        #expect(context.layout.box.height == 600)
        #expect(context.style.font == .times)
        #expect(context.style.fontSize == 14)
        #expect(context.style.color == .blue)
        #expect(context.style.lineHeight == 1.5)
    }

    @Test
    func `Uses default values`() {
        let context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter
        )

        #expect(context.layout.box.llx == 0)
        #expect(context.layout.box.lly == 0)
        #expect(context.style.font == .helvetica)
        #expect(context.style.fontSize == 12)
        #expect(context.style.color == .black)
        #expect(context.style.lineHeight == 1.2)
    }

    @Test
    func `Creates context from mediaBox and margins`() {
        let context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(all: 72)
        )

        #expect(context.layout.box.llx == 72)
        #expect(context.layout.box.lly == 72)
        #expect(context.layout.box.width == 468)
        #expect(context.layout.box.height == 648)
    }

    @Test
    func `Creates context from A4 mediaBox`() {
        let context = PDF.Context(
            mediaBox: .a4,
            margins: PDF.EdgeInsets(all: 72)
        )

        #expect(context.layout.box.llx == 72)
        #expect(context.layout.box.lly == 72)
    }

    // MARK: - Line Height

    @Test
    func `Calculates line height points`() {
        let context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.2
        )

        // Tolerance comparison: 1.2 cannot be exactly represented in IEEE 754
        let lineHeight = context.style.line.height
        #expect(lineHeight > 14.39 && lineHeight < 14.41)
    }

    @Test
    func `Different font sizes affect line height`() {
        let small = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter,
            fontSize: 10,
            lineHeight: 1.2
        )

        let large = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter,
            fontSize: 20,
            lineHeight: 1.2
        )

        #expect(large.style.line.height == small.style.line.height * 2.0)
    }

    // MARK: - Advance Methods

    @Test
    func `Advance line moves Y by line height`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter,
            fontSize: 12,
            lineHeight: 1.2
        )

        let startY = context.layout.box.lly
        context.advance.line()

        // Tolerance comparison: 1.2 cannot be exactly represented in IEEE 754
        let advancedHeight: PDF.UserSpace.Dy = context.layout.box.lly - startY
        #expect(advancedHeight > 14.39 && advancedHeight < 14.41)
    }

    @Test
    func `Advance Y by specific amount`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter
        )

        context.advance(PDF.UserSpace.Height(50))

        #expect(context.layout.box.lly == 50)
    }

    @Test
    func `Multiple advance calls accumulate`() {
        var context = PDF.Context(
            y: 100,
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter
        )

        context.advance(PDF.UserSpace.Height(10))
        context.advance(PDF.UserSpace.Height(20))
        context.advance(PDF.UserSpace.Height(30))

        #expect(context.layout.box.lly == 160)
    }

    // MARK: - Mutability

    @Test
    func `Context is mutable`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            mediaBox: .letter
        )

        context.layout.box.llx = 100
        context.layout.box.lly = 200
        context.style.font = .courier.bold
        context.style.fontSize = 16
        context.style.color = .red

        #expect(context.layout.box.llx == 100)
        #expect(context.layout.box.lly == 200)
        #expect(context.style.font == .courier.bold)
        #expect(context.style.fontSize == 16)
        #expect(context.style.color == .red)
    }
}
