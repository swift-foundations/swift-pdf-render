import Layout_Primitives
import PDF_Rendering_Test_Support
import PDF_Standard
import Testing

@testable import PDF_Rendering

extension PDF.Context {
    @Suite
    struct `Edge Case` {

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

                context.page.ensure(height: 200)
            }

            #expect(context.completedPages.isEmpty)

            #expect(context.layout.box.lly == 72)

            #expect(context.mode.measurement == false)

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

                #expect(outer.mode.measurement == true)
            }

            #expect(context.mode.measurement == false)
        }

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

            context.advance(693)
            #expect(context.layout.box.lly == 765)

            let row = PDF.Stack(.horizontal, spacing: 10) {
                PDF.Text("Cell 1")
                PDF.Text("Cell 2")
                PDF.Text("Cell 3")
            }
            PDF.Stack._render(row, context: &context)

            #expect(context.completedPages.count == 1)
        }
    }
}
