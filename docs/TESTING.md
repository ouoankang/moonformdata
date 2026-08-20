# Testing

This project is designed so review commands can be reproduced from a fresh checkout.

## Required Commands

```bash
moon fmt --check
moon check --deny-warn
moon build
moon test --deny-warn
moon check --target js
moon build --target js
moon test --target js
moon run cmd/main
moon run examples/basic
moon run examples/governance
moon info
moon package --list
```

## Coverage Map

| Area | Covered by |
| --- | --- |
| Boundary and `Content-Type` parsing | `moonformdata_test.mbt`, `edge_test.mbt`, `moonformdata_wbtest.mbt` |
| `Content-Disposition`, `filename`, `filename*` | `advanced_test.mbt`, `edge_test.mbt`, `moonformdata_wbtest.mbt` |
| Multipart body parser | `moonformdata_test.mbt`, `edge_test.mbt`, `corpus_test.mbt` |
| Encoder and roundtrip behavior | `moonformdata_test.mbt`, `advanced_test.mbt`, `corpus_test.mbt` |
| Query helpers | `advanced_test.mbt`, `analysis_test.mbt` |
| Security filename helpers | `advanced_test.mbt`, `edge_test.mbt` |
| Validation policy | `advanced_test.mbt`, `corpus_test.mbt` |
| Declarative schema validation | `schema_test.mbt` |
| Analysis and reporting helpers | `analysis_test.mbt` |
| Upload contracts and acceptance decisions | `contract_test.mbt` |
| Contract compatibility and breaking changes | `evolution_test.mbt` |
| Request conformance suites and reports | `conformance_test.mbt` |
| Endpoint catalog and conformance matrix | `catalog_test.mbt` |
| Persisted baselines and behavior diffs | `baseline_test.mbt` |
| Whitebox helper invariants | `moonformdata_wbtest.mbt` |
| Runnable examples | `cmd/main`, `examples/basic`, `examples/governance` |

## Regression Corpus

`regression_corpus.mbt` provides 84 generated multipart fixtures. The corpus covers repeated fields, multiple upload names, empty uploads, custom content types, and normal upload requests. Corpus tests parse every fixture, verify the declared shape, run validation, and rebuild a roundtrip body for the first fixture.

## Test Count

The current suite contains 112 tests. It covers normal paths, malformed headers, missing boundaries, repeated fields, empty files, parser limits, schema validation, upload contracts, risk thresholds, contract evolution, conformance cases, endpoint routing, baseline serialization, behavior regression detection, helper formatting, and JS target compatibility.

## CI

GitHub Actions runs public checks on push, pull request, and manual dispatch. The CI job installs MoonBit, verifies formatting, runs zero-warning checks, builds both default and JS targets, runs all three examples, verifies generated public interfaces, and lists the package contents.
