# MoonFormData API

MoonFormData provides an in-memory `multipart/form-data` parser, encoder, validation layer, upload contract runtime, compatibility analyzer, conformance suite, endpoint catalog, and persisted regression baseline for MoonBit HTTP tooling.

## Core Types

| Type | Purpose |
| --- | --- |
| `MediaType` | Parsed media type with normalized `typ`, `subtype`, and parameters. |
| `ContentDisposition` | Parsed part disposition and parameters such as `name`, `filename`, and `filename*`. |
| `FormPart` | One multipart part, representing either a text field or a file. |
| `MultipartForm` | Parsed form with ordered `parts` and the active `boundary`. |
| `ParseOptions` | Limits for part count, header count, and body size. |
| `EncodedForm` | Encoder output with `content_type`, `body`, and `boundary`. |
| `MultipartRequest` | Small request wrapper for HTTP client and test usage. |
| `ValidationPolicy` | General validation policy for required fields, file limits, and duplicate rules. |
| `FormSchema` | Declarative schema for named fields and files. |
| `FormAnalysis` | Structured summary of fields, files, headers, content types, and risk notes. |
| `UploadContract` | Parser limits, named form schema, and accepted risk ceiling for one endpoint. |
| `UploadInspection` | Parsed form, validation report, analysis, and final acceptance decision. |
| `ContractDiff` | Ordered compatibility changes between two upload contract versions. |
| `UploadConformanceCase` | One request with expected decision, issue codes, and risk. |
| `ConformanceSuiteResult` | Aggregate result and deterministic report for a request batch. |
| `UploadContractCatalog` | Versioned contracts indexed by endpoint ID and HTTP route. |
| `ConformanceBaseline` | Stable, serializable behavior snapshot for one suite. |
| `BaselineDiff` | Added, removed, changed, and regressed suite behavior. |

## Parsing

| API | Description |
| --- | --- |
| `boundary_from_content_type(header)` | Extract and validate the `boundary` parameter. |
| `parse_multipart(body, boundary)` | Parse an in-memory multipart body with default limits. |
| `parse_multipart_with_options(body, boundary, options)` | Parse with caller supplied limits. |
| `parse_multipart_request(content_type, body)` | Parse a request by reading the boundary from `Content-Type`. |
| `parse_multipart_request_with_options(content_type, body, options)` | Request parser with explicit limits. |

## Encoding

| API | Description |
| --- | --- |
| `encode_multipart(parts, boundary?)` | Encode ordered parts into a multipart body. |
| `encode_fields(fields, boundary?)` | Encode text fields only. |
| `encode_files(files, boundary?)` | Encode file specs only. |
| `encode_fields_and_files(fields, files, boundary?)` | Encode mixed text fields and files. |
| `build_request_from_fields(fields, boundary?)` | Build a request wrapper for text fields. |
| `build_upload_request(fields, files, boundary?)` | Build a request wrapper for common upload flows. |

## Part Helpers

| API | Description |
| --- | --- |
| `text_part(name, value)` | Create a text field part. |
| `file_part(name, filename, body, content_type?)` | Create a file part and sanitize the filename. |
| `empty_file_part(name, filename, content_type?)` | Create an empty file part. |
| `part_add_header(part, name, value)` | Add a safe custom header. |
| `part_replace_header(part, name, value)` | Replace or add a custom header. |
| `part_remove_header(part, name)` | Remove a header by case-insensitive name. |
| `FormPart::encoded_header_block()` | Build the header block used by the encoder. |

## Query Helpers

| API | Description |
| --- | --- |
| `MultipartForm::field_value(name)` | First text value for a field. |
| `MultipartForm::field_values(name)` | All text values for a field. |
| `MultipartForm::files(name)` | All file parts for a file field. |
| `MultipartForm::field_names()` | Distinct text field names. |
| `MultipartForm::file_field_names()` | Distinct file field names. |
| `MultipartForm::require_field(name)` | Required text field as `Result`. |
| `MultipartForm::require_file(name)` | Required file field as `Result`. |
| `MultipartForm::summary()` | Counts for parts, fields, files, and body size. |
| `MultipartForm::debug_lines()` | Stable diagnostic lines for CLIs and logs. |

## Validation

| API | Description |
| --- | --- |
| `default_validation_policy()` | Permissive general policy. |
| `strict_validation_policy()` | Stricter policy for API endpoints. |
| `validate_form(form, policy)` | Validate required fields, files, size, type, and duplicates. |
| `ValidationReport::is_ok()` | Whether no issue was found. |
| `ValidationReport::summary()` | Short status line. |
| `field_rule(name)` | Declarative text field rule. |
| `file_rule(name)` | Declarative file field rule. |
| `default_form_schema()` | Schema that allows unknown fields and files. |
| `strict_form_schema()` | Schema that rejects unknown fields and files. |
| `validate_form_schema(form, schema)` | Validate a form against named field and file rules. |

## Security Helpers

| API | Description |
| --- | --- |
| `safe_filename(filename)` | Remove path separators, drive prefixes, and control characters. |
| `sanitize_filename_with_policy(filename, policy)` | Apply a configurable filename policy. |
| `strict_filename_policy()` | Filename policy for API upload endpoints. |
| `image_filename_policy()` | Filename policy for image uploads. |
| `filename_security_notes(filename)` | Human-readable normalization notes. |

## Upload Contracts

| API | Description |
| --- | --- |
| `upload_contract(schema)` | Create an endpoint contract with conservative parser limits. |
| `UploadContract::with_parse_options(options)` | Replace request parsing limits. |
| `UploadContract::with_max_risk(risk)` | Set the highest accepted analysis risk. |
| `inspect_upload(content_type, body, contract)` | Parse, validate, analyze, and decide in one call. |
| `inspect_upload_request(request, contract)` | Inspect a `MultipartRequest` wrapper. |
| `inspect_parsed_form(form, contract)` | Inspect a form that was already parsed. |
| `UploadInspection::decision_line()` | Stable one-line endpoint decision. |
| `UploadInspection::rejection_reasons()` | Schema and risk reasons for a rejected request. |
| `UploadInspection::to_lines()` | Deterministic report for logs, CI, and API tests. |

## Analysis

| API | Description |
| --- | --- |
| `analyze_form(form)` | Build a structured field, file, header, and risk summary. |
| `analyze_request(request)` | Parse and analyze a request wrapper. |
| `request_analysis_lines(request)` | Return printable analysis lines. |
| `form_name_counts(form)` | Count repeated part names. |
| `form_content_type_counts(form)` | Count file content types. |
| `detect_boundary_in_part_bodies(form)` | Detect active boundary markers inside parsed part bodies. |

## Contract Evolution

| API | Description |
| --- | --- |
| `compare_upload_contracts(previous, current)` | Compare parser limits, risk ceiling, schema flags, field rules, and file rules. |
| `ContractDiff::has_breaking_changes()` | Whether an existing accepted request may now be rejected. |
| `ContractDiff::highest_impact()` | Highest compatibility impact in the report. |
| `ContractDiff::to_lines()` | Stable text output for CI and logs. |
| `ContractDiff::to_markdown()` | Review-friendly compatibility table. |

The analyzer marks new required entries, tightened limits, closed unknown-entry policies, narrower allowlists, and stricter risk ceilings as breaking changes. Relaxed constraints and expanded allowlists are compatible changes.

## Conformance Suites

| API | Description |
| --- | --- |
| `upload_conformance_case(name, request, expectation)` | Create a case from `MultipartRequest`. |
| `raw_upload_conformance_case(...)` | Create a case from raw Content-Type and body values. |
| `UploadConformanceCase::require_issue_code(code)` | Require a schema issue in the observed result. |
| `UploadConformanceCase::with_expected_risk(risk)` | Require a specific analysis risk. |
| `run_conformance_suite(name, contract, cases)` | Execute a deterministic case batch. |
| `ConformanceSuiteResult::failed_cases()` | Return only failed cases. |
| `ConformanceSuiteResult::to_markdown()` | Render a CI or review report. |

## Endpoint Catalog

| API | Description |
| --- | --- |
| `upload_endpoint(id, method, path, version, contract)` | Validate and create a versioned endpoint entry. |
| `upload_contract_catalog()` | Create an empty immutable-style catalog. |
| `UploadContractCatalog::add(endpoint)` | Add an endpoint while rejecting duplicate IDs and routes. |
| `UploadContractCatalog::inspect_route(method, path, request)` | Route and inspect one upload request. |
| `endpoint_conformance_plan(endpoint_id, suite_name, cases)` | Assign a suite to one endpoint. |
| `run_catalog_conformance(name, catalog, plans)` | Execute a multi-endpoint conformance matrix. |

## Regression Baselines

| API | Description |
| --- | --- |
| `conformance_baseline(suite)` | Capture observable case outcomes and issue codes. |
| `ConformanceBaseline::to_text()` | Serialize a stable line-oriented baseline. |
| `parse_conformance_baseline(source)` | Parse and validate a stored baseline. |
| `compare_conformance_baseline(previous, current)` | Detect removed coverage, result changes, failures, and issue-code drift. |
| `BaselineDiff::has_regressions()` | Whether current behavior contains a regression. |
| `BaselineDiff::to_markdown()` | Render a behavior-diff report. |

## Error Model

All fallible APIs return `Result[..., MultipartError]`.

| Error | Meaning |
| --- | --- |
| `MissingBoundary` | `Content-Type` lacks a boundary parameter. |
| `InvalidBoundary(value)` | Boundary is empty, too long, or contains unsafe characters. |
| `InvalidHeader(value)` | Header line or header name is invalid. |
| `InvalidContentType(value)` | `Content-Type` is not valid `multipart/form-data`. |
| `InvalidContentDisposition(value)` | Part disposition is invalid or missing required fields. |
| `MalformedBody(value)` | Body framing, separators, or closing boundary are invalid. |
| `LimitExceeded(value)` | Parser options rejected body size, part count, or header count. |

Catalog routing and baseline parsing expose separate structured errors through `CatalogError`, `CatalogInspectionError`, and `BaselineError`.
