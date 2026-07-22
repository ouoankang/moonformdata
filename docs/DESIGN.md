# Design

## Goal

MoonFormData is a MoonBit native library for parsing, generating, validating, and inspecting `multipart/form-data` payloads. It targets upload endpoints, webhook tooling, API tests, HTTP clients, lightweight gateways, and Web framework integration.

## Non-Goals

| Not included in v0.1.0 | Reason |
| --- | --- |
| Full HTTP server | The project is a reusable multipart library, not a Web framework. |
| Streaming large-file parser | v0.1.0 uses a clear in-memory design that is easier to verify during the hackathon cycle. |
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
