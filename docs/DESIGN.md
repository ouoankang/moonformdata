# Design

## Goal

MoonFormData is a MoonBit native toolkit for parsing, generating, validating, inspecting, and governing `multipart/form-data` payloads. It targets upload endpoints, webhook tooling, API tests, HTTP clients, lightweight gateways, and Web framework integration.

## Non-Goals

| Not included in v0.1.0 | Reason |
| --- | --- |
| Full HTTP server | The project is a reusable multipart library, not a Web framework. |
| Streaming large-file parser | The bounded in-memory layer keeps application validation deterministic; byte streaming remains a separate transport concern. |
| Recursive nested multipart parsing | The common engineering path is flat browser/API upload forms. |
| Browser `FormData` compatibility matrix | The library focuses on interoperable multipart request bodies and MoonBit APIs. |
| Storage, temporary files, or cloud upload adapters | Callers decide where parsed file bodies are stored. |

## Architecture

| Layer | Files | Responsibility |
| --- | --- | --- |
| Core parser and encoder | `moonformdata.mbt` | Boundary extraction, media type parsing, multipart framing, header parsing, encoder output, error model. |
| Part construction | `parts.mbt` | Text/file part helpers, custom headers, builder API. |
| Query API | `form_queries.mbt` | Field/file lookup, summary, required values, debug lines. |
| Header helpers | `headers.mbt` | Content type utilities, `Content-Disposition`, RFC 5987 filename helpers. |
| Security helpers | `security.mbt` | Filename normalization and filename policy. |
| Validation policy | `validation.mbt` | Required fields/files, size limits, duplicate rules, content type policy. |
| Declarative schema | `schema.mbt` | Named field and file rules for application-facing validation. |
| Analysis helpers | `analysis.mbt` | Field/file/header profiles, content type counts, risk notes, stable reporting lines. |
| Upload contract | `contract.mbt` | Combines parser limits, schema validation, risk ceilings, and endpoint decisions. |
| Contract evolution | `evolution.mbt` | Compares versions and classifies breaking, review, and compatible changes. |
| Conformance runner | `conformance.mbt` | Executes named request cases and emits stable text or Markdown reports. |
| Endpoint catalog | `catalog.mbt` | Registers versioned routes and runs multi-endpoint conformance plans. |
| Regression baseline | `baseline.mbt` | Serializes suite behavior and detects coverage or behavior regressions. |
| Recipes | `recipes.mbt` | Request wrappers and common upload/webhook flows. |
| Fixtures | `fixtures.mbt`, `regression_corpus.mbt` | Reusable examples and regression cases. |

## Parser Strategy

The parser validates the boundary before reading body sections. It accepts CRLF and LF-only payloads, keeps part order, preserves repeated fields, and normalizes file names as soon as `Content-Disposition` is parsed. Limits are explicit in `ParseOptions`.

## Encoder Strategy

The encoder always writes `Content-Disposition`, writes `Content-Type` only for file parts or explicit content types, strips header line breaks from custom header values, and omits caller-supplied protected duplicate headers. This keeps generated bodies predictable and suitable for API tests.

## Error Strategy

Fallible APIs return `Result[..., MultipartError]`. Each error variant maps to a clear class of failure so callers can turn parser failures into logs, CLI messages, or HTTP 400 responses.

## Security Notes

Client-provided filenames are never trusted directly. `safe_filename` removes path separators, Windows drive prefixes, control characters, and unsafe empty names. Policy-based sanitizers can block executable extensions, limit length, and restrict allowed extensions.

## Compatibility

The project is implemented in MoonBit and verified on the default target and JS target. No JavaScript, Rust, Python, or C implementation is used for core multipart behavior.

## Governance Model

The application-facing workflow is intentionally deterministic:

1. `UploadContract` defines parser ceilings, a named schema, and the accepted risk level.
2. `compare_upload_contracts` classifies whether a version change can reject previously accepted requests.
3. `run_conformance_suite` proves accepted, rejected, and malformed request behavior with expected issue codes and risks.
4. `UploadContractCatalog` associates contracts with stable endpoint IDs and exact HTTP routes.
5. `ConformanceBaseline` stores observable suite behavior in a line-oriented format suitable for Git diffs.

All reports preserve input order and avoid timestamps or random IDs, so identical inputs produce identical output on the default and JS targets.

## Ecosystem Boundary

MoonFormData uses an in-memory `String` body and targets application-facing request contracts. It does not implement byte streaming or large-file transport. Existing `moon-multipart` packages focus on RFC 7578 streaming parser/writer behavior; MoonFormData focuses on named endpoint schemas, risk analysis, acceptance decisions, API compatibility, conformance matrices, and deterministic baselines. See [ECOSYSTEM.md](ECOSYSTEM.md).
