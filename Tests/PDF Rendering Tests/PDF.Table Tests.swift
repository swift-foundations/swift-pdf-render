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
    /// Uses Pair<Rectangle, Text> for cells with background and content overlaid.
    /// Uses ForEach and ISO structure types - no helper functions.
    @Test
    func `Writes simple table PDF to tmp`() throws {
        let cellWidth: PDF.UserSpace.Width = 100
        let cellHeight: PDF.UserSpace.Height = 24
        let borderColor: PDF.Color = .gray(0.3)
        let headerBg: PDF.Color = .gray(0.9)

        let headers = ["Product", "Units", "Revenue"]
        let dataRows = [
            ["Widget A", "1,234", "$12,340"],
            ["Widget B", "567", "$8,505"],
            ["Widget C", "890", "$17,800"],
        ]

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "Table Rendering Test",
                author: "swift-pdf-rendering",
                creator: "PDF.Table Tests"
            )
        ) {
            PDF.VStack(spacing: 20) {
                PDF.Text("Table Rendering Test", state: .init(fontSize: 24))
                PDF.Divider()

                // Simple 3x3 table
                PDF.Text("Sales Data Q4 2024", state: .init(fontSize: 14))
                PDF.Spacer(4)

                PDF.Table(summary: "Sales data for Q4 2024") {
                    // Header row
                    PDF.THead() {
                        PDF.Table.Row() {
                            PDF.ForEach(headers) { header in
                                PDF.Table.Header.Cell(scope: .column)(
                                    width: cellWidth,
                                    height: cellHeight,
                                    fill: headerBg,
                                    stroke: borderColor
                                ) {
                                    PDF.Text(header, state: .init(fontSize: 11))
                                }
                            }
                        }
                    }

                    // Data rows
                    PDF.Table.Body() {
                        PDF.ForEach(dataRows) { row in
                            PDF.Table.Row() {
                                PDF.ForEach(row) { value in
                                    PDF.Table.Row.Cell()(
                                        width: cellWidth,
                                        height: cellHeight,
                                        stroke: borderColor
                                    ) {
                                        PDF.Text(value, state: .init(fontSize: 10))
                                    }
                                }
                            }
                        }
                    }
                }

                PDF.Spacer(30)
                PDF.Divider()

                // Table with column span
                PDF.Text("Table with Merged Header", state: .init(fontSize: 14))
                PDF.Spacer(4)

                PDF.Table() {
                    // Merged header spanning 2 columns
                    PDF.THead() {
                        PDF.Table.Row() {
                            PDF.Table.Header.Cell(col: .init(span: 2), scope: .column)(
                                width: cellWidth * 2,
                                height: cellHeight,
                                fill: headerBg,
                                stroke: borderColor
                            ) {
                                PDF.Text("Q4 Results (ColSpan: 2)", state: .init(fontSize: 10))
                            }
                            PDF.Table.Header.Cell(scope: .column)(
                                width: cellWidth,
                                height: cellHeight,
                                fill: headerBg,
                                stroke: borderColor
                            ) {
                                PDF.Text("Total", state: .init(fontSize: 11))
                            }
                        }
                    }

                    PDF.Table.Body() {
                        PDF.Table.Row() {
                            PDF.ForEach(["Oct", "Nov", "$38,645"]) { value in
                                PDF.Table.Row.Cell()(
                                    width: cellWidth,
                                    height: cellHeight,
                                    stroke: borderColor
                                ) {
                                    PDF.Text(value, state: .init(fontSize: 10))
                                }
                            }
                        }
                    }
                }
            }
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
    /// Uses ISO structure types and ForEach - no helper functions.
    @Test
    func `Writes complex table PDF to tmp`() throws {
        let cellWidth: PDF.UserSpace.Width = 80
        let rowHeight: PDF.UserSpace.Height = 20
        let headerBg: PDF.Color = .rgb(r: 0.2, g: 0.4, b: 0.6)
        let altRowBg: PDF.Color = .gray(0.95)
        let footerBg: PDF.Color = .gray(0.85)
        let borderColor: PDF.Color = .gray(0.4)

        let headers = ["Region", "Q1", "Q2", "Q3", "Q4", "Total"]
        let dataRows: [(values: [String], alt: Bool)] = [
            (["North", "1,200", "1,350", "1,100", "1,450", "5,100"], false),
            (["South", "980", "1,100", "1,250", "1,180", "4,510"], true),
            (["East", "1,500", "1,420", "1,380", "1,600", "5,900"], false),
            (["West", "1,100", "1,200", "1,150", "1,300", "4,750"], true),
        ]
        let footerValues = ["Total", "4,780", "5,070", "4,880", "5,530", "20,260"]

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "Complex Table Demo",
                author: "swift-pdf-rendering"
            )
        ) {
            PDF.VStack(spacing: 16) {
                PDF.Text("Complex Table Demo", state: .init(fontSize: 20))
                PDF.Text("ISO 32000-2:2020 Table Structure Types", state: .init(fontSize: 12))
                PDF.Spacer(12)

                PDF.Table(summary: "Regional sales summary") {
                    // Header row
                    PDF.THead() {
                        PDF.Table.Row() {
                            PDF.ForEach(headers) { header in
                                PDF.Table.Header.Cell(scope: .column)(
                                    width: cellWidth,
                                    height: rowHeight,
                                    fill: headerBg,
                                    stroke: borderColor
                                ) {
                                    PDF.Text(header, state: .init(fontSize: 10))
                                }
                            }
                        }
                    }

                    // Data rows
                    PDF.Table.Body() {
                        PDF.ForEach(dataRows) { row in
                            PDF.Table.Row() {
                                PDF.ForEach(row.values) { value in
                                    PDF.Table.Row.Cell()(
                                        width: cellWidth,
                                        height: rowHeight,
                                        fill: row.alt ? altRowBg : nil,
                                        stroke: borderColor
                                    ) {
                                        PDF.Text(value, state: .init(fontSize: 9))
                                    }
                                }
                            }
                        }
                    }

                    // Footer row
                    PDF.TFoot() {
                        PDF.Table.Row() {
                            PDF.ForEach(footerValues) { value in
                                PDF.Table.Row.Cell()(
                                    width: cellWidth,
                                    height: rowHeight,
                                    fill: footerBg,
                                    stroke: borderColor
                                ) {
                                    PDF.Text(value, state: .init(fontSize: 10))
                                }
                            }
                        }
                    }
                }

                PDF.Spacer(30)

                // Caption (Table 372)
                PDF.Text("Table: Regional Sales Summary (in thousands)", state: .init(fontSize: 10))
            }
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
    /// Uses Pair directly inside structure type calls - no helper functions.
    @Test
    func `Writes table using ISO structure types`() throws {
        let cellWidth: PDF.UserSpace.Width = 100
        let cellHeight: PDF.UserSpace.Height = 24
        let headerBg: PDF.Color = .gray(0.9)
        let borderColor: PDF.Color = .gray(0.3)

        let pdfDocument = ISO_32000.Document(
            version: .v2_0,
            info: ISO_32000.Document.Info(
                title: "ISO Structure Types Table",
                author: "swift-pdf-rendering"
            )
        ) {
            PDF.VStack(spacing: 20) {
                PDF.Text("ISO 32000 Table Structure Types", state: .init(fontSize: 24))
                PDF.Divider()

                PDF.Text("Table using TH/TD callAsFunction", state: .init(fontSize: 14))
                PDF.Spacer(8)

                // Table with ISO structure types - all using callAsFunction
                PDF.Table(summary: "Product sales data") {
                    PDF.THead() {
                        PDF.Table.Row() {
                            PDF.Table.Header.Cell(scope: .column)(
                                width: cellWidth,
                                height: cellHeight,
                                fill: headerBg,
                                stroke: borderColor
                            ) {
                                PDF.Text("Product", state: .init(fontSize: 11))
                            }
                            PDF.Table.Header.Cell(scope: .column)(
                                width: cellWidth,
                                height: cellHeight,
                                fill: headerBg,
                                stroke: borderColor
                            ) {
                                PDF.Text("Units", state: .init(fontSize: 11))
                            }
                            PDF.Table.Header.Cell(scope: .column)(
                                width: cellWidth,
                                height: cellHeight,
                                fill: headerBg,
                                stroke: borderColor
                            ) {
                                PDF.Text("Revenue", state: .init(fontSize: 11))
                            }
                        }
                    }

                    PDF.Table.Body() {
                        PDF.Table.Row() {
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("Widget A", state: .init(fontSize: 10))
                            }
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("1,234", state: .init(fontSize: 10))
                            }
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("$12,340", state: .init(fontSize: 10))
                            }
                        }
                        PDF.Table.Row() {
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("Widget B", state: .init(fontSize: 10))
                            }
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("567", state: .init(fontSize: 10))
                            }
                            PDF.Table.Row.Cell()(width: cellWidth, height: cellHeight, stroke: borderColor) {
                                PDF.Text("$8,505", state: .init(fontSize: 10))
                            }
                        }
                    }
                }
            }
        }

        let bytes = [UInt8](pdfDocument)
        let url = URL(fileURLWithPath: "/tmp/swift-pdf-rendering-iso-table.pdf")
        try Data(bytes).write(to: url)

        print("ISO table PDF written to: \(url.path)")
        #expect(bytes.count > 0)
    }
}
