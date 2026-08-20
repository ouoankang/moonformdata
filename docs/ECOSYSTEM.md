# Ecosystem Positioning

## Independent Scope

MoonFormData is an original MoonBit implementation for application-facing multipart upload contracts and API governance. It uses a bounded in-memory `String` body model and does not implement streaming byte transport. Its primary output is an acceptance decision, compatibility report, conformance result, or reproducible baseline.

## Public Ecosystem Comparison

| Project | Public focus | Primary integration layer |
| --- | --- | --- |
| MoonFormData | Named field/file schema, risk policy, contract version diff, conformance suites, endpoint catalog, persisted baseline, Markdown reports | API endpoints, webhooks, gateways, and request-test governance |
| [`GCodinggo/moon-multipart`](https://github.com/GCodinggo/moon-multipart) | RFC 7578 byte-oriented streaming parser/writer, chunk-boundary handling, transport limits | HTTP streaming and large-file transport |
| [`Songyz002/moon-multipart`](https://mooncakes.io/docs/Songyz002/moon-multipart) | RFC 7578 streaming parser and generator | HTTP streaming |
| [`mizchi/js`](https://github.com/mizchi/js.mbt) FormData binding | JavaScript/Web API bindings for browser, Node.js, Deno, and edge runtimes | Platform FFI and Web-standard objects |

MoonFormData was designed and implemented independently. None of these projects is a dependency, source reference, fixture source, or porting source.

## Clear Functional Difference

The existing multipart packages solve the transport problem: incrementally read or write RFC-framed bytes. MoonFormData solves the application-contract lifecycle after a complete, bounded request body is available:

- parse a request into an ordered field and file model;
- validate named entries against a closed or open `FormSchema`;
- enforce parser, field, file, type, extension, and risk limits;
- produce an endpoint acceptance or rejection decision;
- compare old and new contracts and classify breaking changes;
- execute expected accept, reject, and parse-error cases in one suite;
- register versioned contracts for multiple HTTP routes;
- serialize observable behavior as a Git-friendly baseline;
- detect removed coverage, changed decisions, new failures, and issue-code drift;
- render deterministic text and Markdown reports for CI and review.

This scope is complementary rather than interchangeable. Applications that require arbitrary binary `Bytes`, incremental parsing, or direct large-file streaming should use a streaming multipart package. Applications that need endpoint-level policy, compatibility checks, reproducible API tests, and stable diagnostics can use MoonFormData directly or place it above an HTTP/streaming adapter.

## Differentiation Evidence

The distinction is implemented and tested, not only described:

| Capability | Implementation | Tests |
| --- | --- | --- |
| Endpoint decision runtime | `contract.mbt` | `contract_test.mbt` |
| Breaking-change analysis | `evolution.mbt` | `evolution_test.mbt` |
| Batch conformance runner | `conformance.mbt` | `conformance_test.mbt` |
| Multi-endpoint catalog | `catalog.mbt` | `catalog_test.mbt` |
| Persisted regression baseline | `baseline.mbt` | `baseline_test.mbt` |
| End-to-end governance flow | `examples/governance` | GitHub Actions CI |

## Provenance and Compliance

The implementation does not copy or port source code, fixtures, or tests from other multipart packages. Protocol behavior is based on public specifications, chiefly RFC 7578, RFC 2046, and RFC 8187. Repository fixtures and regression inputs are project-owned synthetic data. The project is licensed under Apache-2.0.
