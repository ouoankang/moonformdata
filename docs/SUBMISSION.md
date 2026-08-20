# Final Acceptance Evidence

| Item | Value |
| --- | --- |
| Project | MoonFormData |
| Title | MoonFormData: MoonBit native multipart/form-data parser and encoder |
| Package | `ouoankang/moonformdata` |
| Version | `0.1.0` |
| Repository | `https://github.com/ouoankang/moonformdata` |
| License | Apache-2.0 |
| Project type | Original MoonBit open source library |
| Main language | MoonBit |

## Scope

MoonFormData implements an in-memory `multipart/form-data` parser and encoder with application-facing upload contracts. Completed capabilities include boundary and header parsing, repeated fields, file uploads, filename sanitization, request builders, declarative schemas, risk analysis, endpoint decisions, deterministic reports, examples, tests, and CI.

## Existing Foundation

The repository contains a complete MoonBit module, public package metadata, Apache-2.0 license, runnable examples, CI configuration, API documentation, testing documentation, design documentation, ecosystem comparison, 84 regression fixtures, authorship records, and a concise Markdown proposal.

## Technical Route

| Area | Route |
| --- | --- |
| Parsing | Validate boundary, split multipart sections, parse part headers, parse `Content-Disposition`, preserve ordered parts. |
| Encoding | Build deterministic multipart payloads from text and file parts, sanitize filenames, emit HTTP-ready content type. |
| Validation | Provide general policy checks and named schema rules for upload endpoints. |
| Safety | Normalize filenames and reject malformed headers, invalid boundaries, broken bodies, and limit violations. |
| Contract | Combine parse limits, schema rules, and risk ceilings into one acceptance decision and report. |
| Quality | Use blackbox tests for public behavior and whitebox tests for helper invariants. |

## Deliverables

| Deliverable | Location |
| --- | --- |
| Core implementation | Root `.mbt` source files |
| CLI example | `cmd/main` |
| Minimal example | `examples/basic` |
| API documentation | `docs/API.md` |
| Test documentation | `docs/TESTING.md` |
| Design notes | `docs/DESIGN.md` |
| Markdown proposal | `submission/MoonFormData_Project_Proposal.md` |
| Ecosystem comparison | `docs/ECOSYSTEM.md` |
| Commit identity | `AUTHORS.md` |
| CI | `.github/workflows/ci.yml` |

## Verification Commands

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

`moon publish --dry-run` 和 `moon publish` 需要先执行 `moon login`，并确保登录账号有权限发布 `ouoankang/moonformdata`。

## Open Source Compliance

MoonFormData is an original MoonBit implementation under Apache-2.0. It does not copy or port code from existing multipart packages or any private, closed-source, or unclear source. Behavior is designed from public multipart specifications and common HTTP upload practices. Synthetic fixtures and regression data are owned by this project.
