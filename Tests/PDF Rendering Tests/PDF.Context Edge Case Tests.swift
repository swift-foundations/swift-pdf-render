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
    }
}
