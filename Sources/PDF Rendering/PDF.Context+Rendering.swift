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

    public static func _pushBlock(_ context: inout Self, role: Rendering.Semantic.Block?, style: Rendering.Style) {
        context.flush.inline()
        context.scopeStack.append(context.savedScope())
        context.apply(style)

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
            context.style.fontSize = PDF.UserSpace.Size<1>(headingSize)
            context.style.font = context.style.font.bold ?? context.style.font
            if context.lastElementY != nil {
                context.advance(PDF.UserSpace.Height(headingSize * 0.5))
            }

        case .paragraph:
            if context.lastElementY != nil {
                context.advance(context.style.line.height * 0.5)
            }

        case .blockquote:
            context.layoutBox.llx = context.layoutBox.llx + PDF.UserSpace.Width(20)
            context.style.color = .gray(0.4)

        case .pre:
            context.style.font = .courier
            context.preserveWhitespace = true

        case .section, .table, .row, .cell:
            break
        }
    }

    public static func _popBlock(_ context: inout Self) {
        context.flush.inline()
        if let saved = context.scopeStack.popLast() {
            context.restore(saved)
        }
    }

    // MARK: - Inline Structure

    public static func _pushInline(_ context: inout Self, role: Rendering.Semantic.Inline?, style: Rendering.Style) {
        context.scopeStack.append(context.savedScope())
        context.apply(style)

        guard let role else { return }
        switch role {
        case .emphasis:
            context.style.font = context.style.font.italic ?? context.style.font
        case .strong:
            context.style.font = context.style.font.bold ?? context.style.font
        case .code:
            context.style.font = .courier
        }
    }

    public static func _popInline(_ context: inout Self) {
        if let saved = context.scopeStack.popLast() {
            context.restore(saved)
        }
    }

    // MARK: - Lists

    public static func _pushList(_ context: inout Self, kind: Rendering.Semantic.List, start: Int?) {
        context.flush.inline()
        context.scopeStack.append(context.savedScope())

        let pdfKind: PDF.Context.List.Kind = switch kind {
        case .ordered: .ordered(startNumber: start ?? 1)
        case .unordered: .unordered
        }
        context.push(list: pdfKind)
        context.layoutBox.llx = context.layoutBox.llx + PDF.UserSpace.Width(20)
    }

    public static func _popList(_ context: inout Self) {
        context.flush.inline()
        _ = context.listStack.popLast()
        if let saved = context.scopeStack.popLast() {
            context.restore(saved)
        }
    }

    public static func _pushItem(_ context: inout Self) {
        context.flush.inline()
        let marker = context.nextListMarker()
        let markerX = context.layoutBox.llx - PDF.UserSpace.Width(15)
        context.pendingListMarker = (marker: marker, x: markerX)
    }

    public static func _popItem(_ context: inout Self) {
        context.flush.inline()
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

    public static func _pushLink(_ context: inout Self, destination: borrowing String) {
        let copy = copy destination
        context.scopeStack.append(context.savedScope())
        context.style.textMarkup = .underline
        context.style.color = .rgb(r: 0, g: 0, b: 0.8)
        context.currentLinkURL = copy
    }

    public static func _popLink(_ context: inout Self) {
        if let saved = context.scopeStack.popLast() {
            context.restore(saved)
        }
    }

    // MARK: - Page

    public mutating func pageBreak() {
        flush.inline()
        flush.text()
        page.new()
    }
}

// MARK: - Scope Save/Restore

extension PDF.Context {
    /// Capture the current scoped state as a snapshot.
    private func savedScope() -> Scope {
        Scope(
            style: style,
            llx: layoutBox.llx,
            preserveWhitespace: preserveWhitespace,
            currentLinkURL: currentLinkURL
        )
    }

    /// Restore all scoped state from a snapshot.
    private mutating func restore(_ scope: Scope) {
        style = scope.style
        layoutBox.llx = scope.llx
        preserveWhitespace = scope.preserveWhitespace
        currentLinkURL = scope.currentLinkURL
    }
}

// MARK: - Rendering.Style Mapping

extension PDF.Context {
    /// Apply Rendering.Style hints to the current PDF style.
    private mutating func apply(_ style: Rendering.Style) {
        if let size = style.font.size {
            self.style.fontSize = PDF.UserSpace.Size<1>(Double(size))
        }
        if let weight = style.font.weight {
            switch weight {
            case .bold:
                self.style.font = self.style.font.bold ?? self.style.font
            case .normal:
                self.style.font = self.style.font.regular ?? self.style.font
            }
        }
        if let color = style.color {
            self.style.color = PDF.Color(color)
        }
    }
}

// MARK: - PDF.Color ← Rendering.Style.Color

extension PDF.Color {
    /// Creates a PDF color from a rendering style color hint.
    init(_ color: Rendering.Style.Color) {
        self = switch color {
        case .black: .gray(0)
        case .red: .rgb(r: 0.8, g: 0, b: 0)
        case .blue: .rgb(r: 0, g: 0, b: 0.8)
        case .gray: .gray(0.5)
        }
    }
}
