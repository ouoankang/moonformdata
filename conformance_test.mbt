///|
fn conformance_schema() -> @moonformdata.FormSchema {
  @moonformdata.strict_form_schema()
  .add_field_rule(@moonformdata.required_field_rule("title").with_max_values(1))
  .add_file_rule(
    @moonformdata.required_file_rule("upload")
    .with_max_files(1)
    .with_allow_empty(false)
    .allow_content_type("text/plain")
    .allow_extension("txt"),
  )
}

///|
fn conformance_request(
  fields : Array[(String, String)],
  files : Array[@moonformdata.FileSpec],
  boundary : String,
) -> @moonformdata.MultipartRequest {
  @moonformdata.build_upload_request(fields, files, boundary~).unwrap()
}

///|
test "conformance suite passes matching accept reject and parse cases" {
  let accepted = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-ok",
  )
  let rejected = conformance_request(
    [],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-reject",
  )
  let cases = [
    @moonformdata.upload_conformance_case(
      "valid upload",
      accepted,
      @moonformdata.ExpectAccepted,
    ).with_expected_risk(@moonformdata.LowRisk),
    @moonformdata.upload_conformance_case(
      "missing title",
      rejected,
      @moonformdata.ExpectRejected,
    ).require_issue_code("schema_missing_field"),
    @moonformdata.raw_upload_conformance_case(
      "missing boundary",
      "multipart/form-data",
      "body",
      @moonformdata.ExpectParseError,
    ),
  ]
  let suite = @moonformdata.run_conformance_suite(
    "upload-v1",
    @moonformdata.upload_contract(conformance_schema()),
    cases,
  )
  debug_inspect(suite.is_ok(), content="true")
  debug_inspect(suite.passed_count(), content="3")
  debug_inspect(suite.failed_count(), content="0")
}

///|
test "conformance suite reports an unexpected decision" {
  let request = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-mismatch",
  )
  let suite = @moonformdata.run_conformance_suite(
    "mismatch",
    @moonformdata.upload_contract(conformance_schema()),
    [
      @moonformdata.upload_conformance_case(
        "wrong expectation",
        request,
        @moonformdata.ExpectRejected,
      ),
    ],
  )
  debug_inspect(suite.is_ok(), content="false")
  debug_inspect(suite.failed_count(), content="1")
  debug_inspect(suite.cases[0].actual, content="ActualAccepted")
}

///|
test "conformance suite requires declared issue codes" {
  let request = conformance_request(
    [],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-code",
  )
  let suite = @moonformdata.run_conformance_suite(
    "issue-codes",
    @moonformdata.upload_contract(conformance_schema()),
    [
      @moonformdata.upload_conformance_case(
        "wrong issue",
        request,
        @moonformdata.ExpectRejected,
      ).require_issue_code("schema_unknown_field"),
    ],
  )
  debug_inspect(suite.cases[0].passed, content="false")
  debug_inspect(
    suite.cases[0].details[0],
    content="\"missing issue code: schema_unknown_field\"",
  )
}

///|
test "conformance suite validates expected risk" {
  let request = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-risk",
  )
  let suite = @moonformdata.run_conformance_suite(
    "risk",
    @moonformdata.upload_contract(conformance_schema()),
    [
      @moonformdata.upload_conformance_case(
        "risk mismatch",
        request,
        @moonformdata.ExpectAccepted,
      ).with_expected_risk(@moonformdata.HighRisk),
    ],
  )
  debug_inspect(suite.cases[0].passed, content="false")
  debug_inspect(suite.cases[0].details.length(), content="1")
}

///|
test "conformance suite rejects duplicate case names" {
  let request = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-duplicate",
  )
  let case = @moonformdata.upload_conformance_case(
    "same name",
    request,
    @moonformdata.ExpectAccepted,
  )
  let suite = @moonformdata.run_conformance_suite(
    "duplicates",
    @moonformdata.upload_contract(conformance_schema()),
    [case, case],
  )
  debug_inspect(suite.passed_count(), content="1")
  debug_inspect(suite.failed_count(), content="1")
  debug_inspect(
    suite.cases[1].details[0],
    content="\"duplicate conformance case name\"",
  )
}

///|
test "conformance suite exposes failed cases" {
  let request = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-failed",
  )
  let suite = @moonformdata.run_conformance_suite(
    "failed-filter",
    @moonformdata.upload_contract(conformance_schema()),
    [
      @moonformdata.upload_conformance_case(
        "passes",
        request,
        @moonformdata.ExpectAccepted,
      ),
      @moonformdata.raw_upload_conformance_case(
        "fails",
        "multipart/form-data",
        "bad",
        @moonformdata.ExpectAccepted,
      ),
    ],
  )
  let failed = suite.failed_cases()
  debug_inspect(failed.length(), content="1")
  debug_inspect(failed[0].name, content="\"fails\"")
}

///|
test "conformance suite renders deterministic lines and markdown" {
  let request = conformance_request(
    [("title", "hello")],
    [@moonformdata.text_file_spec("upload", "note.txt", "body")],
    "suite-render",
  )
  let suite = @moonformdata.run_conformance_suite(
    "upload|v1",
    @moonformdata.upload_contract(conformance_schema()),
    [
      @moonformdata.upload_conformance_case(
        "valid|request",
        request,
        @moonformdata.ExpectAccepted,
      ),
    ],
  )
  debug_inspect(
    suite.summary(),
    content="\"conformance-suite=upload|v1, cases=1, passed=1, failed=0\"",
  )
  debug_inspect(suite.to_lines().length(), content="2")
  let markdown = suite.to_markdown()
  debug_inspect(markdown.find("upload\\|v1") is Some(_), content="true")
  debug_inspect(markdown.find("valid\\|request") is Some(_), content="true")
}
