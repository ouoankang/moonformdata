# Changelog

## 0.1.0 - 2026-08-20

- Add MoonBit native `multipart/form-data` parser and encoder.
- Add `Content-Type`, `Content-Disposition`, `filename`, and `filename*` parsing helpers.
- Add text field, repeated field, file upload, empty file, and custom header support.
- Add safe filename handling and configurable filename policies.
- Add validation policies for required fields, files, content types, duplicate rules, and size limits.
- Add declarative schema validation for named fields and files.
- Add request wrappers, debug reports, form analysis, risk notes, and regression fixtures.
- Add `UploadContract` and `UploadInspection` for endpoint schema, risk threshold, decision, and deterministic reporting.
- Add upload contract compatibility analysis with breaking-change classification and Markdown reports.
- Add batch conformance suites for expected decisions, schema issue codes, and risk levels.
- Add a versioned multi-endpoint contract catalog and conformance matrix.
- Add serializable behavior baselines with regression and issue-code drift detection.
- Add 112 tests covering parser, encoder, security, contracts, evolution, conformance, catalog, and baseline behavior.
- Add CLI, basic, and governance examples plus README, API, testing, design, ecosystem, CI, and Markdown proposal material.
