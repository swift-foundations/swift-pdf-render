// PDF.Context Edge Case Tests.swift

import Layout_Primitives
import PDF_Rendering_Test_Support
import PDF_Standard
import Testing

@testable import PDF_Rendering

extension PDF.Context {
    @Suite
    struct `Edge Case` {

        // MARK: - F-003: measurement mode soundness

        @Test
        func `Measure across a page boundary completes no real pages`() {
            var context = PDF.Context(
                x: 72,
                y: 72,
                availableWidth: 400,
                availableHeight: 100,
                mediaBox: .letter
            )

            let measured = context.measure { context in
                // Requires more height than the page has left: a page break
                // fires inside measurement mode.
                context.page.ensure(height: 200)
            }

            // Measurement must be side-effect free: no completed pages.
            #expect(context.completedPages.isEmpty)
            // Layout position restored to where measurement started.
            #expect(context.layout.box.lly == 72)
            // Measurement mode is off again after the measure call.
            #expect(context.mode.measurement == false)
            // The virtual page break contributes the remaining page height.
            #expect(measured > 0)
        }

        @Test
        func `Nested measure preserves the outer measurement flag`() {
            var context = PDF.Context(
                x: 72,
                y: 72,
                availableWidth: 400,
                availableHeight: 600,
                mediaBox: .letter
            )

            _ = context.measure { outer in
                _ = outer.measure { _ in }
                // The inner measure must restore, not clobber, the flag.
                #expect(outer.mode.measurement == true)
            }

            #expect(context.mode.measurement == false)
        }

        // MARK: - F-004: horizontal row pagination

        @Test
        func `Horizontal row near the page bottom breaks once, not once per cell`() {
            var context = PDF.Context(
                x: 72,
                y: 72,
                availableWidth: 400,
                availableHeight: 700,
                mediaBox: .letter,
                fontSize: 12,
                lineHeight: 1.0
            )

            // Advance to within one row-height of the page bottom
            // (maxY = 772, line height = 12).
            context.advance(693)
            #expect(context.layout.box.lly == 765)

            let row = PDF.Stack(.horizontal, spacing: 10) {
                PDF.Text("Cell 1")
                PDF.Text("Cell 2")
                PDF.Text("Cell 3")
            }
            PDF.Stack._render(row, context: &context)

            // The whole row must move to the next page as one unit: exactly
            // one page break, not one page per cell.
            #expect(context.completedPages.count == 1)
        }
    }
}
