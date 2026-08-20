///|
fn baseline_contract() -> @moonformdata.UploadContract {
  @moonformdata.upload_contract(
    @moonformdata.strict_form_schema().add_field_rule(
      @moonformdata.required_field_rule("title"),
    ),
  )
}

///|
fn baseline_suite(
  suite_name : String,
  case_name : String,
  expectation : @moonformdata.ConformanceExpectation,
) -> @moonformdata.ConformanceSuiteResult {
  let request = @moonformdata.build_request_from_fields(
    [("title", "hello")],
    boundary="baseline-suite",
  ).unwrap()
  @moonformdata.run_conformance_suite(suite_name, baseline_contract(), [
    @moonformdata.upload_conformance_case(case_name, request, expectation),
  ])
}

///|
test "conformance baseline text roundtrips escaped names" {
  let suite = baseline_suite(
    "upload\tregression",
    "valid,request%one",
    @moonformdata.ExpectAccepted,
  )
  let baseline = @moonformdata.conformance_baseline(suite)
  let text = baseline.to_text()
  debug_inspect(text.find("%09") is Some(_), content="true")
  debug_inspect(text.find("%2C") is Some(_), content="true")
  match @moonformdata.parse_conformance_baseline(text) {
    Ok(parsed) => debug_inspect(parsed == baseline, content="true")
    Err(err) => fail(err.message())
  }
}

///|
test "conformance baseline rejects invalid headers" {
  debug_inspect(
    @moonformdata.parse_conformance_baseline("not-a-baseline\n"),
    content="Err(InvalidBaselineHeader(\"not-a-baseline\"))",
  )
}

///|
test "conformance baseline rejects invalid percent escapes" {
  let source = "moonformdata-conformance-baseline-v1\nsuite\tbad%ZZ\n"
  debug_inspect(
    @moonformdata.parse_conformance_baseline(source),
    content="Err(InvalidBaselineEscape(\"bad%ZZ\"))",
  )
}

///|
test "baseline diff reports unchanged behavior" {
  let current = baseline_suite(
    "upload-v1",
    "accepted",
    @moonformdata.ExpectAccepted,
  )
  let baseline = @moonformdata.conformance_baseline(current)
  let diff = @moonformdata.compare_conformance_baseline(baseline, current)
  debug_inspect(diff.is_unchanged(), content="true")
  debug_inspect(diff.has_regressions(), content="false")
}

///|
test "baseline diff detects removed and added cases" {
  let previous_suite = baseline_suite(
    "upload-v1",
    "old case",
    @moonformdata.ExpectAccepted,
  )
  let current = baseline_suite(
    "upload-v1",
    "new case",
    @moonformdata.ExpectAccepted,
  )
  let diff = @moonformdata.compare_conformance_baseline(
    @moonformdata.conformance_baseline(previous_suite),
    current,
  )
  debug_inspect(diff.regression_count(), content="1")
  debug_inspect(diff.compatible_count(), content="1")
  debug_inspect(diff.changes[0].kind, content="BaselineCaseRemoved")
  debug_inspect(diff.changes[1].kind, content="BaselineCaseAdded")
}

///|
test "baseline diff detects pass to fail regressions" {
  let previous_suite = baseline_suite(
    "upload-v1",
    "decision",
    @moonformdata.ExpectAccepted,
  )
  let current = baseline_suite(
    "upload-v1",
    "decision",
    @moonformdata.ExpectRejected,
  )
  let diff = @moonformdata.compare_conformance_baseline(
    @moonformdata.conformance_baseline(previous_suite),
    current,
  )
  debug_inspect(diff.has_regressions(), content="true")
  debug_inspect(diff.regression_count(), content="1")
  debug_inspect(diff.review_count(), content="1")
  debug_inspect(diff.changes[1].kind, content="BaselinePassStatusChanged")
}

///|
test "baseline diff detects issue code changes" {
  let missing_request = @moonformdata.build_request_from_fields(
    [("other", "value")],
    boundary="baseline-issues",
  ).unwrap()
  let current = @moonformdata.run_conformance_suite(
    "issues",
    baseline_contract(),
    [
      @moonformdata.upload_conformance_case(
        "missing title",
        missing_request,
        @moonformdata.ExpectRejected,
      ).require_issue_code("schema_missing_field"),
    ],
  )
  let baseline : @moonformdata.ConformanceBaseline = {
    suite_name: "issues",
    entries: [
      {
        name: "missing title",
        expectation: @moonformdata.ExpectRejected,
        actual: @moonformdata.ActualRejected,
        passed: true,
        issue_codes: ["old_issue"],
      },
    ],
  }
  let diff = @moonformdata.compare_conformance_baseline(baseline, current)
  debug_inspect(diff.review_count(), content="1")
  debug_inspect(diff.changes[0].kind, content="BaselineIssueCodesChanged")
}

///|
test "baseline diff reports suite renames and renders markdown" {
  let previous_suite = baseline_suite(
    "upload-v1",
    "accepted",
    @moonformdata.ExpectAccepted,
  )
  let current = baseline_suite(
    "upload|v2",
    "accepted",
    @moonformdata.ExpectAccepted,
  )
  let diff = @moonformdata.compare_conformance_baseline(
    @moonformdata.conformance_baseline(previous_suite),
    current,
  )
  debug_inspect(diff.review_count(), content="1")
  debug_inspect(diff.to_lines().length(), content="2")
  debug_inspect(
    diff.to_markdown().find("upload\\|v2") is Some(_),
    content="true",
  )
}
