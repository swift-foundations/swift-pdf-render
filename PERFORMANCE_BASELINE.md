# Performance Baseline

**Date:** 2025-12-17
**Commit:** After swift-iso-32000 0.3.0 optimization
**Platform:** arm64e-apple-macos14.0

## Text Rendering

| Test | Chars | Before | After | Improvement |
|------|-------|--------|-------|-------------|
| Short text | 10 | 83.42µs | **75.38µs** | ~10% faster |
| Medium text | 100 | 546.17µs | **258.92µs** | **~53% faster** |
| Long text | 1000 | 4.07ms | **1.66ms** | **~59% faster** |
| Very long text | 10000 | 41.74ms | **16.71ms** | **~60% faster** |

**Scaling:** ~10x content → ~7-8x time (sublinear, good)

## TextRun Encoding (WinAnsi)

| Test | Chars | Median | Min | p95 |
|------|-------|--------|-----|-----|
| Short | 10 | 39.46µs | 39.08µs | - |
| Medium | 100 | 42.04µs | 41.67µs | - |
| Long | 1000 | 62.21µs | 62.04µs | - |

**Note:** Encoding is fast - ~25µs overhead + ~0.025µs/char

## Document Generation

| Test | Elements | Median | Min |
|------|----------|--------|-----|
| Single | 1 | 126.54µs | 125.38µs |
| 10 elements | 10 | 695.83µs | 682.25µs |
| 100 elements | 100 | 10.01ms | 9.88ms |

**Scaling:** 10x elements → ~8x time (sublinear)

## Throughput

| Metric | Before | After |
|--------|--------|-------|
| **Docs/sec** | 4,290 | ~4,300 |

## Key Improvements (swift-iso-32000 0.3.0)

The upstream optimization in swift-iso-32000 made width calculation the canonical byte primitive:

1. **Direct byte-to-width lookup table** - O(1) array lookup per byte
2. **String width uses byte primitive** - encodes to WinAnsi, then byte lookup
3. **No dictionary lookup overhead** - all widths from pre-computed 256-entry array

### swift-iso-32000 Performance
| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| WinAnsi bytes (100) | 17,000/sec | 163,000/sec | **9.6x** |
| String (100 chars) | 26,000/sec | 512,000/sec | **20x** |

### Downstream Impact
The text rendering improvements (53-60% faster) are a direct result of the upstream width calculation optimization.
