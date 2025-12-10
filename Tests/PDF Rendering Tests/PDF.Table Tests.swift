// PDF.Table Tests.swift
// Visual table rendering tests - writes PDFs to /tmp

import Testing
import Foundation
@testable import PDF_Rendering
import PDF_Standard
import Algebra

@Suite
struct `PDF.Table Tests` {

    /// Renders a simple table to PDF for visual inspection.
    /// Uses Tagged<Rectangle, Text> for cells with background and content overlaid.
    @Test
    func `Writes simple table PDF to tmp`() throws {
        let cellWidth: PDF.UserSpace.Width = 100
        let cellHeight: PDF.UserSpace.Height = 24
        let borderColor: PDF.Color = .gray(0.3)
        let headerBg: PDF.Color = .gray(0.9)

        struct TableDocument: PDF.View {
            let cellWidth: PDF.UserSpace.Width
            let cellHeight: PDF.UserSpace.Height
            let borderColor: PDF.Color
            let headerBg: PDF.Color

            var body: some PDF.View {
                PDF.VStack(spacing: 20) {
                    PDF.Text("Table Rendering Test", state: .init(fontSize: 24))
                    PDF.Divider()

                    // Simple 3x3 table
                    PDF.Text("Sales Data Q4 2024", state: .init(fontSize: 14))
                    PDF.Spacer(4)

                    // Table rows with no spacing between them
                    PDF.VStack(spacing: 0) {
                        // Header row
                        PDF.HStack {
                            tableCell("Product", isHeader: true)
                            tableCell("Units", isHeader: true)
                            tableCell("Revenue", isHeader: true)
                        }

                        // Data rows
                        PDF.HStack {
                            tableCell("Widget A")
                            tableCell("1,234")
                            tableCell("$12,340")
                        }

                        PDF.HStack {
                            tableCell("Widget B")
                            tableCell("567")
                            tableCell("$8,505")
                        }

                        PDF.HStack {
                            tableCell("Widget C")
                            tableCell("890")
                            tableCell("$17,800")
                        }
                    }

                    PDF.Spacer(30)
                    PDF.Divider()

                    // Table with column span simulation
                    PDF.Text("Table with Merged Header", state: .init(fontSize: 14))
                    PDF.Spacer(4)

                    PDF.VStack(spacing: 0) {
                        // Merged header spanning 2 columns
                        PDF.HStack {
                            Pair(
                                PDF.Rectangle(
                                    width: cellWidth * 2,
                                    height: cellHeight,
                                    fill: headerBg,
                                    stroke: borderColor
                                ),
                                PDF.Text("Q4 Results (ColSpan: 2)", state: .init(fontSize: 10))
                            )
                            tableCell("Total", isHeader: true)
                        }

                        PDF.HStack {
                            tableCell("Oct")
                            tableCell("Nov")
                            tableCell("$38,645")
                        }
                    }
                }
            }

            func tableCell(_ text: String, isHeader: Bool = false) -> some PDF.View {
                Pair(
                    PDF.Rectangle(
                        width: cellWidth,
                        height: cellHeight,
                        fill: isHeader ? headerBg : nil,
                        stroke: borderColor
                    ),
                    PDF.Text(text, state: .init(fontSize: isHeader ? 11 : 10))
                )
            }
        }

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "Table Rendering Test",
                author: "swift-pdf-rendering",
                creator: "PDF.Table Tests"
            )
        ) {
            TableDocument(
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                borderColor: borderColor,
                headerBg: headerBg
            )
        }

        let bytes = [UInt8](pdfDocument)
        let url = URL(fileURLWithPath: "/tmp/swift-pdf-rendering-table.pdf")
        try Data(bytes).write(to: url)

        print("Table PDF written to: \(url.path)")
        #expect(bytes.count > 0)
    }

    /// Demonstrates ISO 32000 table structure types in use.
    /// These types define the semantic structure, not visual rendering.
    @Test
    func `ISO 32000 table structure types`() {
        // Table 371 - Table structure types
        let table = ISO_32000.Table(
            summary: "Quarterly sales data for accessibility"
        )

        // Header cell with scope (Table 384)
        let productHeader = ISO_32000.TH(
            scope: .column,
            short: "Prod"
        )

        // Header spanning 2 columns (Table 384)
        let mergedHeader = ISO_32000.TH(
            col: .init(span: 2),
            scope: .column
        )

        // Data cell referencing headers (Table 384)
        let dataCell = ISO_32000.TD(
            headers: ["product-col", "q4-row"]
        )

        // Row groupings (Table 371)
        let thead = ISO_32000.THead()
        let tbody = ISO_32000.TBody()
        let tfoot = ISO_32000.TFoot()

        // Verify structure
        #expect(table.summary != nil)
        #expect(productHeader.scope == .column)
        #expect(mergedHeader.col.span == 2)
        #expect(dataCell.headers.count == 2)
        #expect(thead == ISO_32000.THead())
        #expect(tbody == ISO_32000.TBody())
        #expect(tfoot == ISO_32000.`14`.`8`.`4`.`8`.`3`.TFoot())
    }

    /// Writes a more complex table with row/column spans to PDF.
    @Test
    func `Writes complex table PDF to tmp`() throws {
        let cellWidth: PDF.UserSpace.Width = 80
        let rowHeight: PDF.UserSpace.Height = 20
        let headerBg: PDF.Color = .rgb(r: 0.2, g: 0.4, b: 0.6)
        let headerText: PDF.Color = .gray(1.0)
        let altRowBg: PDF.Color = .gray(0.95)
        let borderColor: PDF.Color = .gray(0.4)

        struct ComplexTableDocument: PDF.View {
            let cellWidth: PDF.UserSpace.Width
            let rowHeight: PDF.UserSpace.Height
            let headerBg: PDF.Color
            let headerText: PDF.Color
            let altRowBg: PDF.Color
            let borderColor: PDF.Color

            var body: some PDF.View {
                PDF.VStack(spacing: 16) {
                    PDF.Text("Complex Table Demo", state: .init(fontSize: 20))
                    PDF.Text("ISO 32000-2:2020 Table Structure Types", state: .init(fontSize: 12))
                    PDF.Spacer(12)

                    // Table rows with no spacing between them
                    PDF.VStack(spacing: 0) {
                        // Header row
                        PDF.HStack {
                            headerCell("Region")
                            headerCell("Q1")
                            headerCell("Q2")
                            headerCell("Q3")
                            headerCell("Q4")
                            headerCell("Total")
                        }

                        // Data rows with alternating background
                        dataRow(["North", "1,200", "1,350", "1,100", "1,450", "5,100"], alt: false)
                        dataRow(["South", "980", "1,100", "1,250", "1,180", "4,510"], alt: true)
                        dataRow(["East", "1,500", "1,420", "1,380", "1,600", "5,900"], alt: false)
                        dataRow(["West", "1,100", "1,200", "1,150", "1,300", "4,750"], alt: true)

                        // Footer row
                        PDF.HStack {
                            footerCell("Total")
                            footerCell("4,780")
                            footerCell("5,070")
                            footerCell("4,880")
                            footerCell("5,530")
                            footerCell("20,260")
                        }
                    }

                    PDF.Spacer(30)

                    // Caption (Table 372)
                    PDF.Text("Table: Regional Sales Summary (in thousands)", state: .init(fontSize: 10))
                }
            }

            func headerCell(_ text: String) -> some PDF.View {
                Pair(
                    PDF.Rectangle(width: cellWidth, height: rowHeight, fill: headerBg, stroke: borderColor),
                    PDF.Text(text, state: .init(fontSize: 10))
                )
            }

            func dataRow(_ values: [String], alt: Bool) -> some PDF.View {
                PDF.HStack {
                    for value in values {
                        Pair(
                            PDF.Rectangle(
                                width: cellWidth,
                                height: rowHeight,
                                fill: alt ? altRowBg : nil,
                                stroke: borderColor
                            ),
                            PDF.Text(value, state: .init(fontSize: 9))
                        )
                    }
                }
            }

            func footerCell(_ text: String) -> some PDF.View {
                Pair(
                    PDF.Rectangle(width: cellWidth, height: rowHeight, fill: .gray(0.85), stroke: borderColor),
                    PDF.Text(text, state: .init(fontSize: 10))
                )
            }
        }

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "Complex Table Demo",
                author: "swift-pdf-rendering"
            )
        ) {
            ComplexTableDocument(
                cellWidth: cellWidth,
                rowHeight: rowHeight,
                headerBg: headerBg,
                headerText: headerText,
                altRowBg: altRowBg,
                borderColor: borderColor
            )
        }

        let bytes = [UInt8](pdfDocument)
        let url = URL(fileURLWithPath: "/tmp/swift-pdf-rendering-complex-table.pdf")
        try Data(bytes).write(to: url)

        print("Complex table PDF written to: \(url.path)")
        #expect(bytes.count > 0)
    }

    /// Minimal test using ISO 32000 table structure types with callAsFunction.
    ///
    /// This demonstrates using Table, TR, TH, TD as callable types that wrap content.
    @Test
    func `Writes table using ISO structure types`() throws {
       

        let cellWidth: PDF.UserSpace.Width = 100
        let cellHeight: PDF.UserSpace.Height = 24
        let headerBg: PDF.Color = .gray(0.9)
        let borderColor: PDF.Color = .gray(0.3)

        // Helper for header cells
        func headerCell(_ text: String) -> some PDF.View {
            Pair(
                PDF.Rectangle(width: cellWidth, height: cellHeight, fill: headerBg, stroke: borderColor),
                PDF.Text(text, state: .init(fontSize: 11))
            )
        }

        // Helper for data cells
        func dataCell(_ text: String) -> some PDF.View {
            Pair(
                PDF.Rectangle(width: cellWidth, height: cellHeight, stroke: borderColor),
                PDF.Text(text, state: .init(fontSize: 10))
            )
        }

        struct ISOTableDocument: PDF.View {
            let cellWidth: PDF.UserSpace.Width
            let cellHeight: PDF.UserSpace.Height
            let headerBg: PDF.Color
            let borderColor: PDF.Color

//            typealias Table = ISO_32000.Table
//            typealias TR = ISO_32000.`14`.`8`.`4`.`8`.`3`.TR
//            typealias TH = ISO_32000.TH
//            typealias TD = ISO_32000.TD
//            typealias THead = ISO_32000.THead
//            typealias TBody = ISO_32000.TBody

            
            var body: some PDF.View {
                PDF.VStack(spacing: 20) {
                    PDF.Text("ISO 32000 Table Structure Types", state: .init(fontSize: 24))
                    PDF.Divider()

                    PDF.Text("Table using TH/TD callAsFunction", state: .init(fontSize: 14))
                    PDF.Spacer(8)

                    // Table with ISO structure types
                    PDF.Table(summary: "Product sales data") {
                        PDF.VStack(spacing: 0) {
                            PDF.THead() {
                                PDF.TR() {
                                    PDF.HStack {
                                        PDF.Table.Header.Cell(scope: .column) { headerCell("Product") }
                                        PDF.Table.Header.Cell(scope: .column) { headerCell("Units") }
                                        PDF.Table.Header.Cell(scope: .column) { headerCell("Revenue") }
                                    }
                                }
                            }

                            PDF.TBody() {
                                PDF.TR() {
                                    PDF.HStack {
                                        PDF.TD() { dataCell("Widget A") }
                                        PDF.TD() { dataCell("1,234") }
                                        PDF.TD() { dataCell("$12,340") }
                                    }
                                }
                                PDF.TR() {
                                    PDF.HStack {
                                        PDF.TD() { dataCell("Widget B") }
                                        PDF.TD() { dataCell("567") }
                                        PDF.TD() { dataCell("$8,505") }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            func headerCell(_ text: String) -> some PDF.View {
                Pair(
                    PDF.Rectangle(width: cellWidth, height: cellHeight, fill: headerBg, stroke: borderColor),
                    PDF.Text(text, state: .init(fontSize: 11))
                )
            }

            func dataCell(_ text: String) -> some PDF.View {
                Pair(
                    PDF.Rectangle(width: cellWidth, height: cellHeight, stroke: borderColor),
                    PDF.Text(text, state: .init(fontSize: 10))
                )
            }
        }

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "ISO Structure Types Table",
                author: "swift-pdf-rendering"
            )
        ) {
            ISOTableDocument(
                cellWidth: cellWidth,
                cellHeight: cellHeight,
                headerBg: headerBg,
                borderColor: borderColor
            )
        }

        let bytes = [UInt8](pdfDocument)
        let url = URL(fileURLWithPath: "/tmp/swift-pdf-rendering-iso-table.pdf")
        try Data(bytes).write(to: url)

        print("ISO table PDF written to: \(url.path)")
        #expect(bytes.count > 0)
    }
}
