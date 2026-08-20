# Ecosystem Positioning

## Independent Scope

MoonFormData is an original MoonBit implementation for application-facing multipart upload contracts. Its primary output is an acceptance decision with schema issues, risk analysis, and deterministic diagnostics. It uses an in-memory `String` body model and does not implement streaming byte transport.

## Public Ecosystem Comparison

| Project | Public focus | Primary integration layer |
| --- | --- | --- |
| MoonFormData | `UploadContract`, named field/file schema, unknown-entry policy, risk threshold, analysis reports, 84-fixture regression corpus | API endpoints, webhooks, gateways, and request-test tooling |
| [`GCodinggo/moon-multipart`](https://github.com/GCodinggo/moon-multipart) | RFC 7578, byte-oriented streaming parser/writer, chunk boundary handling, transport safety limits | HTTP streaming and large-file transport |
| [`Songyz002/moon-multipart`](https://mooncakes.io/docs/Songyz002/moon-multipart) | Mooncakes metadata describes an RFC 7578 streaming parser and generator | HTTP streaming |

The MoonFormData repository started on 2026-07-22. The Mooncakes registry records the first `Songyz002/moon-multipart` release on 2026-07-29 and the first `GCodinggo/moon-multipart` release on 2026-08-03. MoonFormData was designed and implemented independently; neither package is a dependency, source reference, or porting source.

## Functional Boundary

MoonFormData deliberately does not duplicate streaming parsers. It focuses on the layer after a complete request body is available:

- parse a bounded in-memory multipart body;
- validate named fields and files against `FormSchema`;
- reject unknown entries where an endpoint contract is closed;
- enforce part, header, request, file, and field limits;
- classify file and form risk;
- combine parsing, schema validation, and risk ceilings through `UploadContract`;
- emit stable reports for CI, API tests, webhook debugging, and acceptance evidence.

Applications that require arbitrary binary `Bytes`, incremental parsing, or direct large-file streaming should use a streaming multipart package. Applications that need endpoint-level contract validation and deterministic diagnostics can use MoonFormData directly or place it above an HTTP adapter.

## Provenance and Compliance

The implementation does not copy or port source code, fixtures, or tests from other multipart packages. Protocol behavior is based on public specifications, chiefly RFC 7578, RFC 2046, and RFC 8187. Repository fixtures and regression inputs are project-owned synthetic data. The project is licensed under Apache-2.0.
