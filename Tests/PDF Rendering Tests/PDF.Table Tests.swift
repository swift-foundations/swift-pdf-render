// PDF.Table Tests.swift
// Table rendering test - writes PDF to /tmp for visual inspection

import Foundation
import PDF_Standard
import Testing

@testable import PDF_Rendering

@Suite
struct `PDF.Table Tests` {

    /// Renders a table demonstrating ISO 32000-2:2020 table structure types.
    ///
    /// Features:
    /// - THead, TBody, TFoot row groupings
    /// - TH with scope attribute for accessibility
    /// - TD data cells
    /// - ColSpan for merged headers
    /// - Alternating row backgrounds
    /// - PDF.ForEach for iteration
    @Test
    func `Writes table PDF to tmp`() throws {
        let cellWidth: PDF.UserSpace.Width = 80
        let rowHeight: PDF.UserSpace.Height = 20
        let headerBg: PDF.Color = .rgb(r: 0.2, g: 0.4, b: 0.6)
        let altRowBg: PDF.Color = .gray(0.95)
        let footerBg: PDF.Color = .gray(0.85)
        let borderStroke: PDF.Stroke = .init(.gray(0.4))

        let headers = ["Region", "Q1", "Q2", "Q3", "Q4", "Total"]
        let dataRows: [(values: [String], alt: Bool)] = [
            (["North", "1,200", "1,350", "1,100", "1,450", "5,100"], false),
            (["South", "980", "1,100", "1,250", "1,180", "4,510"], true),
            (["East", "1,500", "1,420", "1,380", "1,600", "5,900"], false),
            (["West", "1,100", "1,200", "1,150", "1,300", "4,750"], true),
        ]
        let footerValues = ["Total", "4,780", "5,070", "4,880", "5,530", "20,260"]

        let pdfDocument = PDF.Document(
            configuration: .init(
                version: .v2_0,
                info: .init(
                    title: "Table Test",
                    author: "swift-pdf-rendering"
                )
            )
        ) {
            PDF.VStack(spacing: 16) {
                PDF.Text("ISO 32000-2:2020 Table Structure Types", state: .init(fontSize: 18))
                PDF.Spacer(8)

                PDF.Table(summary: "Regional sales summary") {
                    PDF.Table.Header()(headers) { header in
                        PDF.Table.Header.Cell(scope: .column)(
                            width: cellWidth,
                            height: rowHeight,
                            fill: headerBg,
                            stroke: borderStroke
                        ) {
                            PDF.Text(header, state: .init(fontSize: 10))
                        }
                    }

                    PDF.Table.Body()(dataRows) { row in
                        PDF.Table.Row()(row.values) { value in
                            PDF.Table.Row.Cell()(
                                width: cellWidth,
                                height: rowHeight,
                                fill: row.alt ? altRowBg : nil,
                                stroke: borderStroke
                            ) {
                                PDF.Text(value, state: .init(fontSize: 9))
                            }
                        }
                    }

                    PDF.TFoot()(footerValues) { value in
                        PDF.Table.Row.Cell()(
                            width: cellWidth,
                            height: rowHeight,
                            fill: footerBg,
                            stroke: borderStroke
                        ) {
                            PDF.Text(value, state: .init(fontSize: 10))
                        }
                    }
                }

                PDF.Spacer(20)
                PDF.Text("Table: Regional Sales Summary (in thousands)", state: .init(fontSize: 10))
            }
        }

        let bytes = [UInt8](pdfDocument)

        let path = try PDFOutput.write(bytes, name: "table")

        print("PDF written to: \(path)")
        #expect(!bytes.isEmpty)
    }
}
