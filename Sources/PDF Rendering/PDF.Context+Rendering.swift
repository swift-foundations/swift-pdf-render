// PDF.Context+Rendering.swift
// Rendering.Context conformance for cross-format rendering.
//
// Maps the 15 semantic methods to existing PDF.Context infrastructure,
// enabling the same Rendering.View tree to render through both
// HTML.Context and PDF.Context.

import Layout_Primitives
public import PDF_Standard
public import Rendering_Primitives

// MARK: - Rendering.Context Conformance

extension PDF.Context: Rendering.Context {

    // MARK: - Text

    public mutating func text(_ content: borrowing String) {
        let copy = copy content
        let run = PDF.Context.Text.Run(
            text: copy,
            font: style.font,
            fontSize: style.fontSize,
            color: style.color,
            textDecoration: style.textMarkup,
            verticalOffset: style.verticalOffset,
            linkURL: currentLinkURL
        )
        append(inline: run)
    }

    // MARK: - Block Structure

    public mutating func pushBlock(role: Rendering.Semantic.Block?, style: Rendering.Style) {
        // Flush pending inline content before starting a new block
        flush.inline()

        // Save current style for restoration in popBlock
        renderingStyleStack.append(self.style)

        // Apply Rendering.Style hints to PDF style
        applyRenderingStyle(style)

        // Apply role-specific formatting
        guard let role else { return }
        switch role {
        case .heading(let level):
            let headingSize: Double = switch level {
            case 1: 24
            case 2: 20
            case 3: 16
            case 4: 14
            case 5: 12
            default: 11
            }
            self.style.fontSize = PDF.UserSpace.Size<1>(headingSize)
            self.style.font = self.style.font.bold ?? self.style.font
            // Spacing before heading
            if lastElementY != nil {
                advance(PDF.UserSpace.Height(headingSize * 0.5))
            }

        case .paragraph:
            // Spacing before paragraph
            if lastElementY != nil {
                advance(self.style.line.height * 0.5)
            }

        case .blockquote:
            // Indent and use gray color
            layoutBox.llx = layoutBox.llx + PDF.UserSpace.Width(20)
            self.style.color = .gray(0.4)

        case .pre:
            self.style.font = .courier
            preserveWhitespace = true

        case .section, .table, .row, .cell:
            break
        }
    }

    public mutating func popBlock() {
        flush.inline()

        // Restore style
        if let saved = renderingStyleStack.popLast() {
            self.style = saved
        }

        preserveWhitespace = false
    }

    // MARK: - Inline Structure

    public mutating func pushInline(role: Rendering.Semantic.Inline?, style: Rendering.Style) {
        // Save style (inline runs accumulate — don't flush)
        renderingStyleStack.append(self.style)

        applyRenderingStyle(style)

        guard let role else { return }
        switch role {
        case .emphasis:
            self.style.font = self.style.font.italic ?? self.style.font
        case .strong:
            self.style.font = self.style.font.bold ?? self.style.font
        case .code:
            self.style.font = .courier
        }
    }

    public mutating func popInline() {
        if let saved = renderingStyleStack.popLast() {
            self.style = saved
        }
    }

    // MARK: - Lists

    public mutating func pushList(kind: Rendering.Semantic.List, start: Int?) {
        flush.inline()
        let pdfKind: PDF.Context.List.Kind = switch kind {
        case .ordered: .ordered(startNumber: start ?? 1)
        case .unordered: .unordered
        }
        push(list: pdfKind)

        // Indent for list content
        layoutBox.llx = layoutBox.llx + PDF.UserSpace.Width(20)
    }

    public mutating func popList() {
        flush.inline()

        // Pop the list stack (call the existing method on self)
        _ = listStack.popLast()

        // Outdent
        layoutBox.llx = layoutBox.llx - PDF.UserSpace.Width(20)
    }

    public mutating func pushItem() {
        flush.inline()
        let marker = nextListMarker()
        let markerX = layoutBox.llx - PDF.UserSpace.Width(15)
        pendingListMarker = (marker: marker, x: markerX)
    }

    public mutating func popItem() {
        flush.inline()
    }

    // MARK: - Breaks

    public mutating func lineBreak() {
        flush.inline()
        advance.line()
    }

    public mutating func thematicBreak() {
        flush.inline()
        advance(PDF.UserSpace.Height(6))
        let from = PDF.UserSpace.Coordinate(x: layoutBox.llx, y: layoutBox.lly)
        let to = PDF.UserSpace.Coordinate(x: layoutBox.llx + layoutBox.width, y: layoutBox.lly)
        emit.line(from: from, to: to, color: .gray(0.7), width: PDF.UserSpace.Width(0.5))
        advance(PDF.UserSpace.Height(6))
    }

    // MARK: - Media

    public mutating func image(source: String, alt: String) {
        // PDF image embedding requires resolved image data.
        // Emit alt text as fallback for cross-format rendering.
        flush.inline()
        let run = PDF.Context.Text.Run(
            text: alt.isEmpty ? "[image]" : "[\(alt)]",
            font: style.font.italic ?? style.font,
            fontSize: style.fontSize,
            color: .gray(0.5)
        )
        append(inline: run)
        flush.inline()
    }

    // MARK: - Links

    public mutating func pushLink(destination: borrowing String) {
        let copy = copy destination
        renderingStyleStack.append(self.style)
        style.textMarkup = .underline
        style.color = .rgb(r: 0, g: 0, b: 0.8)
        currentLinkURL = copy
    }

    public mutating func popLink() {
        currentLinkURL = nil
        if let saved = renderingStyleStack.popLast() {
            self.style = saved
        }
    }

    // MARK: - Page

    public mutating func pageBreak() {
        flush.inline()
        flush.text()
        page.new()
    }
}

// MARK: - Helpers

extension PDF.Context {
    /// Apply Rendering.Style hints to the current PDF style.
    private mutating func applyRenderingStyle(_ style: Rendering.Style) {
        if let fontSize = style.fontSize {
            self.style.fontSize = PDF.UserSpace.Size<1>(Double(fontSize))
        }
        if let fontWeight = style.fontWeight {
            switch fontWeight {
            case .bold:
                self.style.font = self.style.font.bold ?? self.style.font
            case .normal:
                self.style.font = self.style.font.regular ?? self.style.font
            }
        }
        if let color = style.color {
            self.style.color = color.pdfColor
        }
    }
}

// MARK: - Rendering.Style.Color → PDF.Color

extension Rendering.Style.Color {
    var pdfColor: PDF.Color {
        switch self {
        case .black: .gray(0)
        case .red: .rgb(r: 0.8, g: 0, b: 0)
        case .blue: .rgb(r: 0, g: 0, b: 0.8)
        case .gray: .gray(0.5)
        }
    }
}
