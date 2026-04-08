# Audit: swift-pdf-rendering

## Legacy — Consolidated 2026-04-08

### From: swift-institute/Research/modularization-audit-foundations-batch-B.md (2026-03-20)

**Modularization audit — MOD-001 through MOD-014**

2 products: PDF Rendering, PDF Rendering Test Support.

| Rule | Status | Notes |
|------|--------|-------|
| MOD-001 | N/A | Main + Test Support pattern |
| MOD-002 | N/A | Single main target |
| MOD-003 | N/A | No variant targets |
| MOD-004 | N/A | No ~Copyable concerns |
| MOD-005 | N/A | Single main product |
| MOD-006 | PASS | 5 deps — all justified (PDF Standard, Rendering Primitives, CoW, Layout, Property) |
| MOD-007 | PASS | Depth 1 |
| MOD-008 | PASS | 34 files |
| MOD-009 | N/A | No inline variants |
| MOD-010 | N/A | No stdlib extensions |
| MOD-011 | PASS | PDF Rendering Test Support published as library product |
| MOD-012 | PASS | Correct L3 naming |
| MOD-013 | N/A | 3 targets, threshold is 5 |
| MOD-014 | N/A | No cross-package optional integration |

**Findings**: 0 FAIL. Clean compliance.

---

### From: swift-institute/Research/rendering-architecture-audit.md (2026-03-13)

**Skill**: implementation, naming — [API-NAME-001], [API-NAME-002], [IMPL-INTENT]

| # | Severity | Rule | Finding | Status |
|---|----------|------|---------|--------|
| PDF-C-001 | CRITICAL | [API-NAME-002] | 28+ compound stored property names on PDF.Context in PDF.Context.swift:42-172. Requires nested namespace decomposition (`layout.*`, `box.margin.*`, `text.*`, `pagination.*`). Track as design project. | OPEN -- Design project |
| PDF-C-002 | CRITICAL | [API-NAME-002] | `updateHorizontalRowMaxY` compound method in PDF.Context.swift:303. | OPEN |
| PDF-C-003 | CRITICAL | [API-NAME-002] | `nextListMarker` compound method in PDF.Context.swift:353. | OPEN |
| PDF-C-004 | CRITICAL | [API-NAME-002] | `addLinkAnnotation`/`addPendingInternalLink` compound methods in PDF.Context.swift:407-444. | OPEN |
| PDF-C-005 | CRITICAL | Architectural | Scope captures only 4 fields but push operations can modify uncaptured state in PDF.Context.Scope.swift:14-19. Add `lastElementY` and `stackSpacing` to Scope. | OPEN -- See D7 |
| PDF-H-001 | HIGH | [API-NAME-002] | `setFillColor`/`setStrokeColor` compound internal methods in PDF.Context.swift:562-583. | OPEN |
| PDF-H-002 | HIGH | [API-NAME-002] | `applyRenderingStyle` compound private method in PDF.Context+Rendering.swift:218. Rename to `apply(_:)`. | OPEN |
| PDF-H-003 | HIGH | [API-NAME-002] | `pdfColor` compound cross-domain property. Make initializer on target type per [PATTERN-012]. | OPEN |
| PDF-H-004 | HIGH | [API-NAME-002] | `isHorizontalLayout` compound boolean in PDF.Context.swift:298. | OPEN |
| PDF-H-005 | HIGH | [API-NAME-002] | `hasInlineRuns` in PDF.Context.swift:322 -- possibly dead code. Investigate. | OPEN |
| PDF-H-008 | HIGH | [API-NAME-002] | `renderRuns`/`buildActualText` compound methods in PDF.Context.Text.Run+Rendering.swift:17,511. | OPEN |
| PDF-M-005 | MEDIUM | [API-NAME-002] | Compound stored properties on Text.Run: `textDecoration`, `verticalOffset`, `linkURL`, `internalLinkId`. | OPEN |
| PDF-M-006 | MEDIUM | [API-IMPL-005] | `PendingInternalLink` defined inside PDF.Context.swift:182-195. Extract to own file. | OPEN |
| PDF-M-007 | MEDIUM | [API-NAME-001] | `BuilderRaw` leaked public typealias in PDF.Builder.swift:8. Make internal or remove. | OPEN |
| PDF-M-008 | MEDIUM | [API-NAME-001] | `LayoutRaw` leaked public typealias in PDF.Stack+PDF.View.swift:12. | OPEN |

**Architectural notes**: Property.View accessors (`advance`, `emit`, `flush`, `page`) follow [IMPL-020] correctly. Scope save/restore works but has completeness concern (PDF-C-005). All composition types correct.

---

### From: swift-institute/Research/rendering-packages-naming-implementation-audit.md (2026-03-12, SUPERSEDED)

**Skill**: naming, implementation — [API-NAME-001], [API-NAME-002], [IMPL-INTENT], [PATTERN-017]

Additional findings not covered in the rendering-architecture-audit:

| # | Severity | Rule | Finding | Status |
|---|----------|------|---------|--------|
| M-028 | MEDIUM | [IMPL-INTENT] | Repeated color-switch mechanism -- 6 identical blocks in PDF.Context.swift. Extract `setFillColor(_:)` and `setStrokeColor(_:)`. | OPEN |
| M-031 | MEDIUM | [IMPL-INTENT] | If-chain type dispatch in PDF.Element.markedContentInfo:78-154 with `unsafeBitCast`. | OPEN |
| M-033 | MEDIUM | [PATTERN-017] | `.rawValue > 0` comparisons in PDF.HTML+Dispatch.swift:341,352,438,441. Use typed `> .zero`. | OPEN |
| M-034 | MEDIUM | [PATTERN-017] | `.rawValue` in content height calculation in HTML.Element.Tag+TableCell.swift:167. Use typed distance. | OPEN |
| M-037 | MEDIUM | [PATTERN-016] | `try!` in fallback path of markedContentInfo at PDF.Element.swift:152-153. Generic type names can contain non-PDF characters. | OPEN |
| M-038 | MEDIUM | [IMPL-INTENT] | Unused `backgroundColor` parameter in TextRun.init at PDF.Context.TextRun.swift:45. Remove. | OPEN |

---

### From: swift-institute/Research/audits/implementation-naming-2026-03-13/swift-pdf-rendering.md (2026-03-13)

#### Scope

- **Target**: swift-pdf-rendering (PDF Rendering module)
- **Skills**: implementation, code-surface
- **Files scanned**: 49 (35 Sources, 14 Tests)

#### Findings Summary

| Severity | Count | Primary Rule |
|----------|-------|--------------|
| Critical | 8 | [API-NAME-001/002/004] naming violations |
| Style | 18 | [IMPL-EXPR-001], [IMPL-INTENT], [IMPL-034], [IMPL-010] |
| **Total** | **26** | |

#### Violations

**[API-NAME-004] Typealiases for type unification** (4 instances)
- `Sources/PDF Rendering/PDF.Builder.swift:8` -- `BuilderRaw = Rendering.Builder`
- `Sources/PDF Rendering/Rendering/PDF.Stack+PDF.View.swift:12,16,22-29` -- `LayoutRaw`, `PDF.Layout`, `PDF.Stack`/`VStack`/`HStack` (all same type)

**[API-NAME-001] Compound type name `PendingInternalLink`**
- `Sources/PDF Rendering/PDF.Context.swift:182`

**[API-NAME-002] Compound method names** (4 instances)
- `Sources/PDF Rendering/PDF.Context.swift:303,407,430,493`
- `updateHorizontalRowMaxY`, `addLinkAnnotation`, `addPendingInternalLink`, `resolveInternalLinks`

**[API-NAME-002] Compound property names on `PDF.Context`** (30+ stored properties)
- `Sources/PDF Rendering/PDF.Context.swift:56-149`
- `inlineRuns`, `listStack`, `pendingListMarker`, `marginTop`, `paddingLeft`, `currentTextFont`, ... (largest single effort to fix -- requires sub-struct decomposition within @CoW)

**[IMPL-EXPR-001]** Unnecessary intermediate variables (3 instances)
- `Sources/PDF Rendering/PDF.Context.swift:261-262,277-278,514-526`
- `Sources/PDF Rendering/PDF.Context.swift:562-583` (minor)

**[IMPL-030]** Intermediate variables in `Pair._renderRectangleContent`
- `Sources/PDF Rendering/Rendering/Pair+PDF.View.swift:56-99`

**[IMPL-INTENT] Mechanism-heavy text rendering** (146 lines)
- `Sources/PDF Rendering/PDF.Context.Text.Run+Rendering.swift:17-163`
- Performance-justified imperative byte processing

**[IMPL-INTENT] Mechanism-heavy `markedContentInfo`** (type-check chain with `unsafeBitCast`)
- `Sources/PDF Rendering/PDF.Element.swift:78-157`

**[IMPL-034] `unsafe` keyword placement** (4 instances)
- `Sources/PDF Rendering/Rendering/Pair+PDF.View.swift:21`
- `Sources/PDF Rendering/PDF.Element.swift:83,98,120`
- `unsafeBitCast` without `unsafe` block wrapping

**[IMPL-034] `force_try` / [IMPL-040]**
- `Sources/PDF Rendering/PDF.Element.swift:155` -- `try!` on `COS.Name`

**[IMPL-010] Raw `Int` at API surface** (3 instances)
- `Sources/PDF Rendering/PDF.Context.swift:186,496` -- pageNumber
- `Sources/PDF Rendering/PDF.Context.List.Kind.swift:14` -- ordered list startNumber
- `Sources/PDF Rendering/PDF.Context+Rendering.swift:41-48` -- heading level (tolerable boundary)

**[PATTERN-010]** File name mismatch
- `Sources/PDF Rendering/Rendering/Never+PDF.View.swift` -- header says `File.swift`

**[API-IMPL-005]** Multiple types in one file (minor -- private impl types)
- `Sources/PDF Rendering/PDF.Context.Text.Run+Rendering.swift:168-213`

#### Clean Areas

[API-NAME-003], [PATTERN-009] (source only), [IMPL-020], [IMPL-006] (@CoW), one-type-per-file (public types) -- all PASS.
