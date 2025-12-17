# Performance Baseline

**Date:** 2025-12-17
**Commit:** Before optimizations
**Platform:** arm64e-apple-macos14.0

## Text Rendering

| Test | Chars | Median | Min | p95 |
|------|-------|--------|-----|-----|
| Short text | 10 | 83.42µs | 79.33µs | 87.71µs |
| Medium text | 100 | 546.17µs | 517.92µs | 575.17µs |
| Long text | 1000 | 4.07ms | 3.62ms | 4.10ms |
| Very long text | 10000 | 41.74ms | 40.82ms | 48.61ms |

**Scaling:** ~10x content → ~7-8x time (sublinear, good)

## TextRun Encoding (WinAnsi)

| Test | Chars | Median | Min | p95 |
|------|-------|--------|-----|-----|
| Short | 10 | 43.88µs | 39.92µs | 46.04µs |
| Medium | 100 | 46.63µs | 43.42µs | 47.75µs |
| Long | 1000 | 68.96µs | 63.71µs | 74.50µs |

**Note:** Encoding is fast - ~25µs overhead + ~0.025µs/char

## Document Generation

| Test | Elements | Median | Min | p95 |
|------|----------|--------|-----|-----|
| Single | 1 | 147.50µs | 135.54µs | 155.08µs |
| 10 elements | 10 | 1.22ms | 1.17ms | 1.28ms |
| 100 elements | 100 | 22.42ms | 22.00ms | 23.90ms |

**Scaling:** 10x elements → ~8x time (sublinear)

## Throughput

| Metric | Value |
|--------|-------|
| **Docs/sec** | 4,290 |
| **Total generated** | 21,451 in 5s |

## Key Observations

1. **Text rendering dominates** - 4ms for 1000 chars vs 69µs for TextRun encoding
2. **Document overhead is low** - 147µs for single-element doc
3. **Throughput ceiling** - ~4,300 simple docs/sec

## Optimization Targets

Based on profiling plan, expected gains from:
- Font metric caching: ~30%
- Buffer reuse: ~10%
- Style hash comparison: ~15%
- Pre-scan encoding: ~40%

**Target throughput:** 6,000-8,000 docs/sec after quick wins
