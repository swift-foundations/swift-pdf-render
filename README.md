# swift-pdf-render

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Renders declarative `PDF.View` hierarchies into ISO 32000 PDF documents, composing text, stacks, tables, and shapes through a result-builder `body`.

---

## Key Features

- **Declarative views** — Conform a type to `PDF.View` and describe its layout in a `@PDF.Builder` `body`, composing child views instead of emitting content-stream operators by hand.
- **Layout containers** — `PDF.Stack` arranges children vertically or horizontally with spacing; `PDF.Spacer`, `PDF.Divider`, and `PDF.Rectangle` supply fixed geometry and rules.
- **Tables** — `ISO_32000.Table` rows and cells compose through the same builder, flowing cells horizontally and rows vertically.
- **Builder control flow** — `if`/`else` branches, `Optional` content, and `Array` content all conform to `PDF.View`, so a `body` can branch and iterate over data.
- **Byte-accurate text** — `PDF.Text` encodes a `String` to PDF text bytes (WinAnsi) at construction, matching the ISO 32000 content model rather than re-encoding at render time.
- **Configurable assembly** — `PDF.Configuration` carries paper size, margins, default fonts, and document metadata; `PDF.Document` renders a view into pages and assembles the final `ISO_32000.Document`.

---

## Quick Start

Describe a document as a composable view tree — the rendering pipeline walks the tree, lays out each element, and emits the ISO 32000 content stream, so no content-stream operators are written by hand:

```swift
import PDF_Rendering

struct Invoice: PDF.View {
    var body: some PDF.View {
        PDF.Stack(.vertical, spacing: 12) {
            PDF.Text("Invoice #1024")
            PDF.Divider()
            PDF.Text("Amount due: EUR 4,500.00")
        }
    }
}

let document = PDF.Document {
    Invoice()
}
```

`import PDF_Rendering` re-exports the `PDF` namespace, so `PDF.View`, `PDF.Stack`, `PDF.Text`, `PDF.Divider`, and `PDF.Document` are all available from the single import.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-pdf-render.git", branch: "main")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "PDF Rendering", package: "swift-pdf-render")
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26.

---

## Architecture

| Product | Import | When to import |
|---------|--------|----------------|
| `PDF Rendering` | `import PDF_Rendering` | Building PDF documents from `PDF.View` hierarchies in library and application code. |
| `PDF Rendering Test Support` | `import PDF_Rendering_Test_Support` | Test targets asserting against rendered output; re-exports `PDF Rendering` and the dimension test helpers. |

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at first public release.*
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE](LICENSE.md).
