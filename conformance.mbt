///|
/// Expected outcome for one upload contract conformance case.
pub(all) enum ConformanceExpectation {
  ExpectAccepted
  ExpectRejected
  ExpectParseError
} derive(Debug, Eq)

///|
/// Observed outcome while running one upload contract conformance case.
pub(all) enum ConformanceActual {
  ActualAccepted
  ActualRejected
  ActualParseError
} derive(Debug, Eq)

///|
/// One named multipart request and its expected contract behavior.
pub(all) struct UploadConformanceCase {
  name : String
  content_type : String
  body : String
  expectation : ConformanceExpectation
  required_issue_codes : Array[String]
  expected_risk : UploadRisk?
} derive(Debug, Eq)

///|
/// Detailed result for one conformance case.
pub(all) struct ConformanceCaseResult {
  name : String
  expectation : ConformanceExpectation
  actual : ConformanceActual
  passed : Bool
  issue_codes : Array[String]
  details : Array[String]
} derive(Debug, Eq)

///|
/// Aggregate result for a deterministic batch of upload requests.
pub(all) struct ConformanceSuiteResult {
  name : String
  cases : Array[ConformanceCaseResult]
} derive(Debug, Eq)

///|
/// Build a conformance case from a generated or captured request wrapper.
pub fn upload_conformance_case(
  name : String,
  request : MultipartRequest,
  expectation : ConformanceExpectation,
) -> UploadConformanceCase {
  {
    name,
    content_type: request.content_type,
    body: request.body,
    expectation,
    required_issue_codes: [],
    expected_risk: None,
  }
}

///|
/// Build a conformance case directly from HTTP Content-Type and body values.
pub fn raw_upload_conformance_case(
  name : String,
  content_type : String,
  body : String,
  expectation : ConformanceExpectation,
) -> UploadConformanceCase {
  {
    name,
    content_type,
    body,
    expectation,
    required_issue_codes: [],
    expected_risk: None,
  }
}

///|
/// Require a schema issue code to appear when this case is inspected.
pub fn UploadConformanceCase::require_issue_code(
  self : UploadConformanceCase,
  code : String,
) -> UploadConformanceCase {
  let required_issue_codes = conformance_clone_strings(
    self.required_issue_codes,
  )
  if !conformance_contains(required_issue_codes, code) {
    required_issue_codes.push(code)
  }
  {
    name: self.name,
    content_type: self.content_type,
    body: self.body,
    expectation: self.expectation,
    required_issue_codes,
    expected_risk: self.expected_risk,
  }
}

///|
/// Require the form analysis to produce a specific risk level.
pub fn UploadConformanceCase::with_expected_risk(
  self : UploadConformanceCase,
  risk : UploadRisk,
) -> UploadConformanceCase {
  {
    name: self.name,
    content_type: self.content_type,
    body: self.body,
    expectation: self.expectation,
    required_issue_codes: conformance_clone_strings(self.required_issue_codes),
    expected_risk: Some(risk),
  }
}

///|
/// Run a named batch of multipart requests against one upload contract.
pub fn run_conformance_suite(
  name : String,
  contract : UploadContract,
  cases : Array[UploadConformanceCase],
) -> ConformanceSuiteResult {
  let results = Array::new()
  let seen_names : Array[String] = []
  let mut i = 0
  while i < cases.length() {
    if conformance_contains(seen_names, cases[i].name) {
      results.push(duplicate_conformance_result(cases[i]))
    } else {
      seen_names.push(cases[i].name)
      results.push(run_conformance_case(contract, cases[i]))
    }
    i = i + 1
  }
  { name, cases: results }
}

///|
pub fn ConformanceExpectation::label(self : ConformanceExpectation) -> String {
  match self {
    ExpectAccepted => "accepted"
    ExpectRejected => "rejected"
    ExpectParseError => "parse-error"
  }
}

///|
pub fn ConformanceActual::label(self : ConformanceActual) -> String {
  match self {
    ActualAccepted => "accepted"
    ActualRejected => "rejected"
    ActualParseError => "parse-error"
  }
}

///|
pub fn ConformanceCaseResult::status_label(
  self : ConformanceCaseResult,
) -> String {
  if self.passed {
    "pass"
  } else {
    "fail"
  }
}

///|
pub fn ConformanceCaseResult::to_line(self : ConformanceCaseResult) -> String {
  let mut line = self.status_label() +
    "|" +
    self.name +
    "|expected=" +
    self.expectation.label() +
    "|actual=" +
    self.actual.label()
  if self.issue_codes.length() > 0 {
    line = line + "|issues=" + self.issue_codes.join(",")
  }
  if self.details.length() > 0 {
    line = line + "|details=" + self.details.join("; ")
  }
  line
}

///|
pub fn ConformanceSuiteResult::passed_count(
  self : ConformanceSuiteResult,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.cases.length() {
    if self.cases[i].passed {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
pub fn ConformanceSuiteResult::failed_count(
  self : ConformanceSuiteResult,
) -> Int {
  self.cases.length() - self.passed_count()
}

///|
pub fn ConformanceSuiteResult::is_ok(self : ConformanceSuiteResult) -> Bool {
  self.failed_count() == 0
}

///|
pub fn ConformanceSuiteResult::summary(self : ConformanceSuiteResult) -> String {
  "conformance-suite=" +
  self.name +
  ", cases=" +
  self.cases.length().to_string() +
  ", passed=" +
  self.passed_count().to_string() +
  ", failed=" +
  self.failed_count().to_string()
}

///|
pub fn ConformanceSuiteResult::failed_cases(
  self : ConformanceSuiteResult,
) -> Array[ConformanceCaseResult] {
  let failed = Array::new()
  let mut i = 0
  while i < self.cases.length() {
    if !self.cases[i].passed {
      failed.push(self.cases[i])
    }
    i = i + 1
  }
  failed
}

///|
pub fn ConformanceSuiteResult::to_lines(
  self : ConformanceSuiteResult,
) -> Array[String] {
  let lines = [self.summary()]
  let mut i = 0
  while i < self.cases.length() {
    lines.push(self.cases[i].to_line())
    i = i + 1
  }
  lines
}

///|
/// Render a Markdown report suitable for CI artifacts and API review.
pub fn ConformanceSuiteResult::to_markdown(
  self : ConformanceSuiteResult,
) -> String {
  let lines = [
    "# Upload conformance report: " + conformance_markdown_cell(self.name),
    "",
    self.summary(),
    "",
    "| Status | Case | Expected | Actual | Issue codes | Details |",
    "| --- | --- | --- | --- | --- | --- |",
  ]
  let mut i = 0
  while i < self.cases.length() {
    let result = self.cases[i]
    lines.push(
      "| " +
      result.status_label() +
      " | " +
      conformance_markdown_cell(result.name) +
      " | " +
      result.expectation.label() +
      " | " +
      result.actual.label() +
      " | " +
      conformance_markdown_cell(result.issue_codes.join(", ")) +
      " | " +
      conformance_markdown_cell(result.details.join("; ")) +
      " |",
    )
    i = i + 1
  }
  lines.join("\n")
}

///|
fn run_conformance_case(
  contract : UploadContract,
  case : UploadConformanceCase,
) -> ConformanceCaseResult {
  match inspect_upload(case.content_type, case.body, contract) {
    Ok(inspection) => conformance_from_inspection(case, inspection)
    Err(err) => conformance_from_parse_error(case, err)
  }
}

///|
fn conformance_from_inspection(
  case : UploadConformanceCase,
  inspection : UploadInspection,
) -> ConformanceCaseResult {
  let actual = if inspection.is_accepted() {
    ActualAccepted
  } else {
    ActualRejected
  }
  let details = Array::new()
  if !conformance_outcome_matches(case.expectation, actual) {
    details.push(
      "expected " + case.expectation.label() + " but observed " + actual.label(),
    )
  }
  let issue_codes = conformance_issue_codes(inspection.validation)
  let mut i = 0
  while i < case.required_issue_codes.length() {
    if !conformance_contains(issue_codes, case.required_issue_codes[i]) {
      details.push("missing issue code: " + case.required_issue_codes[i])
    }
    i = i + 1
  }
  match case.expected_risk {
    Some(expected) =>
      if inspection.analysis.risk != expected {
        details.push(
          "expected risk " +
          expected.label() +
          " but observed " +
          inspection.analysis.risk.label(),
        )
      }
    None => ()
  }
  {
    name: case.name,
    expectation: case.expectation,
    actual,
    passed: details.length() == 0,
    issue_codes,
    details,
  }
}

///|
fn conformance_from_parse_error(
  case : UploadConformanceCase,
  err : MultipartError,
) -> ConformanceCaseResult {
  let details = Array::new()
  if case.expectation != ExpectParseError {
    details.push(
      "expected " +
      case.expectation.label() +
      " but observed parse-error: " +
      err.message(),
    )
  }
  if case.required_issue_codes.length() > 0 {
    details.push("schema issue codes are unavailable after a parse error")
  }
  if case.expected_risk is Some(_) {
    details.push("risk is unavailable after a parse error")
  }
  {
    name: case.name,
    expectation: case.expectation,
    actual: ActualParseError,
    passed: details.length() == 0,
    issue_codes: [],
    details,
  }
}

///|
fn duplicate_conformance_result(
  case : UploadConformanceCase,
) -> ConformanceCaseResult {
  {
    name: case.name,
    expectation: case.expectation,
    actual: ActualParseError,
    passed: false,
    issue_codes: [],
    details: ["duplicate conformance case name"],
  }
}

///|
fn conformance_outcome_matches(
  expected : ConformanceExpectation,
  actual : ConformanceActual,
) -> Bool {
  match (expected, actual) {
    (ExpectAccepted, ActualAccepted) => true
    (ExpectRejected, ActualRejected) => true
    (ExpectParseError, ActualParseError) => true
    _ => false
  }
}

///|
fn conformance_issue_codes(report : ValidationReport) -> Array[String] {
  let codes = Array::new()
  let mut i = 0
  while i < report.issues.length() {
    if !conformance_contains(codes, report.issues[i].code) {
      codes.push(report.issues[i].code)
    }
    i = i + 1
  }
  codes
}

///|
fn conformance_clone_strings(values : Array[String]) -> Array[String] {
  let copy = Array::new()
  let mut i = 0
  while i < values.length() {
    copy.push(values[i])
    i = i + 1
  }
  copy
}

///|
fn conformance_contains(values : Array[String], target : String) -> Bool {
  let mut i = 0
  while i < values.length() {
    if values[i] == target {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn conformance_markdown_cell(value : String) -> String {
  let out = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let code = value.code_unit_at(i)
    if code == 124 {
      out.write_string("\\|")
    } else if code == 10 || code == 13 {
      out.write_char(' ')
    } else {
      out.write_char(code.unsafe_to_char())
    }
    i = i + 1
  }
  out.to_string()
}
