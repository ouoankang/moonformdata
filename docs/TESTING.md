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
moon info
moon package --list
moon publish --dry-run
```

`moon publish --dry-run` requires `moon login` because the MoonBit toolchain reads Mooncakes credentials before running the publish command.

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
| Whitebox helper invariants | `moonformdata_wbtest.mbt` |
| Runnable examples | `cmd/main`, `examples/basic` |

## Regression Corpus

`regression_corpus.mbt` provides 84 generated multipart fixtures. The corpus covers repeated fields, multiple upload names, empty uploads, custom content types, and normal upload requests. Corpus tests parse every fixture, verify the declared shape, run validation, and rebuild a roundtrip body for the first fixture.

## Test Count

The current suite contains 81 tests. It covers normal paths, malformed headers, missing boundaries, repeated fields, empty files, parser limits, schema validation, upload contracts, risk thresholds, helper formatting, JS target compatibility, and runnable examples.

## CI

GitHub Actions runs public checks on push, pull request, and manual dispatch. The CI job installs MoonBit, verifies formatting, runs zero-warning checks, builds both default and JS targets, runs tests and examples, verifies generated public interfaces, and lists the publish package. The publish dry run is a local release command after `moon login`.
