// PDF.Context Tests.swift

import Testing
@testable import PDF_Rendering
import PDF_Standard

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
            font: .times,
            fontSize: 14,
            color: .blue,
            lineHeight: 1.5
        )

        #expect(context.x == 100)
        #expect(context.y == 200)
        #expect(context.availableWidth == 400)
        #expect(context.availableHeight == 600)
        #expect(context.font == .times)
        #expect(context.fontSize == 14)
        #expect(context.color == .blue)
        #expect(context.lineHeight == 1.5)
    }

    @Test
    func `Uses default values`() {
        let context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600
        )

        #expect(context.x == 0)
        #expect(context.y == 0)
        #expect(context.font == .helvetica)
        #expect(context.fontSize == 12)
        #expect(context.color == .black)
        #expect(context.lineHeight == 1.2)
    }

    @Test
    func `Creates context from mediaBox and margins`() {
        let context = PDF.Context(
            mediaBox: .letter,
            margins: PDF.EdgeInsets(all: 72)
        )

        #expect(context.x == 72)
        #expect(context.y == 72)
        #expect(context.availableWidth == 612 - 144)
        #expect(context.availableHeight == 792 - 144)
    }

    @Test
    func `Creates context from A4 mediaBox`() {
        let context = PDF.Context(
            mediaBox: .a4,
            margins: .standard
        )

        #expect(context.x == 72)
        #expect(context.y == 72)
    }

    // MARK: - Line Height

    @Test
    func `Calculates line height points`() {
        let context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            fontSize: 12,
            lineHeight: 1.2
        )

        // Tolerance comparison: 1.2 cannot be exactly represented in IEEE 754
        #expect(abs(context.lineHeightPoints - 14.4) < 0.001)
    }

    @Test
    func `Different font sizes affect line height`() {
        let small = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            fontSize: 10,
            lineHeight: 1.2
        )

        let large = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            fontSize: 20,
            lineHeight: 1.2
        )

        #expect(large.lineHeightPoints == small.lineHeightPoints * 2)
    }

    // MARK: - Advance Methods

    @Test
    func `Advance line moves Y by line height`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600,
            fontSize: 12,
            lineHeight: 1.2
        )

        let startY = context.y
        context.advanceLine()

        // Tolerance comparison: 1.2 cannot be exactly represented in IEEE 754
        #expect(abs(context.y - (startY + 14.4)) < 0.001)
    }

    @Test
    func `Advance Y by specific amount`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600
        )

        let startY = context.y
        context.advanceY(50)

        #expect(context.y == startY + 50)
    }

    @Test
    func `Multiple advance calls accumulate`() {
        var context = PDF.Context(
            y: 100,
            availableWidth: 400,
            availableHeight: 600
        )

        context.advanceY(10)
        context.advanceY(20)
        context.advanceY(30)

        #expect(context.y == 160)
    }

    // MARK: - Mutability

    @Test
    func `Context is mutable`() {
        var context = PDF.Context(
            availableWidth: 400,
            availableHeight: 600
        )

        context.x = 100
        context.y = 200
        context.font = .courier.bold
        context.fontSize = 16
        context.color = .red

        #expect(context.x == 100)
        #expect(context.y == 200)
        #expect(context.font == .courier.bold)
        #expect(context.fontSize == 16)
        #expect(context.color == .red)
    }
}
