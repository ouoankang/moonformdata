///|
/// Parse errors for the stable MoonFormData conformance baseline format.
pub(all) enum BaselineError {
  InvalidBaselineHeader(String)
  MissingBaselineSuite
  InvalidBaselineLine(String)
  InvalidBaselineExpectation(String)
  InvalidBaselineActual(String)
  InvalidBaselineStatus(String)
  InvalidBaselineEscape(String)
} derive(Debug, Eq)

///|
/// Serializable behavior snapshot for one conformance case.
pub(all) struct ConformanceBaselineEntry {
  name : String
  expectation : ConformanceExpectation
  actual : ConformanceActual
  passed : Bool
  issue_codes : Array[String]
} derive(Debug, Eq)

///|
/// Versioned, text-serializable snapshot of one conformance suite.
pub(all) struct ConformanceBaseline {
  suite_name : String
  entries : Array[ConformanceBaselineEntry]
} derive(Debug, Eq)

///|
/// Impact assigned to a behavior change relative to a stored baseline.
pub(all) enum BaselineChangeImpact {
  BaselineCompatible
  BaselineReview
  BaselineRegression
} derive(Debug, Eq)

///|
/// Kind of behavior change detected between a baseline and a current suite.
pub(all) enum BaselineChangeKind {
  BaselineSuiteRenamed
  BaselineCaseAdded
  BaselineCaseRemoved
  BaselineExpectationChanged
  BaselineActualChanged
  BaselinePassStatusChanged
  BaselineIssueCodesChanged
} derive(Debug, Eq)

///|
/// One deterministic conformance baseline difference.
pub(all) struct BaselineChange {
  impact : BaselineChangeImpact
  kind : BaselineChangeKind
  case_name : String
  before : String
  after : String
} derive(Debug, Eq)

///|
/// Complete baseline comparison for CI regression checks.
pub(all) struct BaselineDiff {
  suite_name : String
  changes : Array[BaselineChange]
} derive(Debug, Eq)

///|
/// Capture the observable result of a conformance suite.
pub fn conformance_baseline(
  suite : ConformanceSuiteResult,
) -> ConformanceBaseline {
  let entries = Array::new()
  let mut i = 0
  while i < suite.cases.length() {
    let result = suite.cases[i]
    entries.push({
      name: result.name,
      expectation: result.expectation,
      actual: result.actual,
      passed: result.passed,
      issue_codes: baseline_clone_strings(result.issue_codes),
    })
    i = i + 1
  }
  { suite_name: suite.name, entries }
}

///|
/// Parse a baseline previously produced by `ConformanceBaseline::to_text`.
pub fn parse_conformance_baseline(
  source : String,
) -> Result[ConformanceBaseline, BaselineError] {
  let lines = source.replace_all(old="\r\n", new="\n").split("\n").collect()
  if lines.length() == 0 || lines[0] != "moonformdata-conformance-baseline-v1" {
    return Err(
      InvalidBaselineHeader(
        if lines.length() == 0 {
          ""
        } else {
          lines[0].to_owned()
        },
      ),
    )
  }
  if lines.length() < 2 || !lines[1].has_prefix("suite\t") {
    return Err(MissingBaselineSuite)
  }
  let suite_line = lines[1].to_owned()
  let suite_name = match baseline_unescape(slice_from(suite_line, 6)) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let entries = Array::new()
  let mut i = 2
  while i < lines.length() {
    if lines[i] != "" {
      match baseline_parse_entry(lines[i].to_owned()) {
        Ok(entry) => entries.push(entry)
        Err(err) => return Err(err)
      }
    }
    i = i + 1
  }
  Ok({ suite_name, entries })
}

///|
/// Compare a stored baseline with a newly executed conformance suite.
pub fn compare_conformance_baseline(
  previous : ConformanceBaseline,
  current : ConformanceSuiteResult,
) -> BaselineDiff {
  let changes = Array::new()
  if previous.suite_name != current.name {
    changes.push({
      impact: BaselineReview,
      kind: BaselineSuiteRenamed,
      case_name: "<suite>",
      before: previous.suite_name,
      after: current.name,
    })
  }
  let mut i = 0
  while i < previous.entries.length() {
    let old_entry = previous.entries[i]
    match baseline_find_result(current.cases, old_entry.name) {
      Some(result) => baseline_compare_entry(old_entry, result, changes)
      None =>
        changes.push({
          impact: BaselineRegression,
          kind: BaselineCaseRemoved,
          case_name: old_entry.name,
          before: baseline_entry_state(old_entry),
          after: "missing",
        })
    }
    i = i + 1
  }
  let mut j = 0
  while j < current.cases.length() {
    let result = current.cases[j]
    if baseline_find_entry(previous.entries, result.name) is None {
      changes.push({
        impact: BaselineCompatible,
        kind: BaselineCaseAdded,
        case_name: result.name,
        before: "missing",
        after: baseline_result_state(result),
      })
    }
    j = j + 1
  }
  { suite_name: current.name, changes }
}

///|
pub fn BaselineError::message(self : BaselineError) -> String {
  match self {
    InvalidBaselineHeader(value) =>
      "invalid conformance baseline header: " + value
    MissingBaselineSuite => "conformance baseline is missing its suite line"
    InvalidBaselineLine(value) => "invalid conformance baseline line: " + value
    InvalidBaselineExpectation(value) =>
      "invalid baseline expectation: " + value
    InvalidBaselineActual(value) => "invalid baseline actual outcome: " + value
    InvalidBaselineStatus(value) => "invalid baseline pass status: " + value
    InvalidBaselineEscape(value) => "invalid baseline percent escape: " + value
  }
}

///|
/// Serialize a baseline using a stable, line-oriented, diff-friendly format.
pub fn ConformanceBaseline::to_text(self : ConformanceBaseline) -> String {
  let lines = [
    "moonformdata-conformance-baseline-v1",
    "suite\t" + baseline_escape(self.suite_name),
  ]
  let mut i = 0
  while i < self.entries.length() {
    lines.push(baseline_serialize_entry(self.entries[i]))
    i = i + 1
  }
  lines.join("\n") + "\n"
}

///|
pub fn BaselineChangeImpact::label(self : BaselineChangeImpact) -> String {
  match self {
    BaselineCompatible => "compatible"
    BaselineReview => "review"
    BaselineRegression => "regression"
  }
}

///|
pub fn BaselineChangeKind::label(self : BaselineChangeKind) -> String {
  match self {
    BaselineSuiteRenamed => "suite-renamed"
    BaselineCaseAdded => "case-added"
    BaselineCaseRemoved => "case-removed"
    BaselineExpectationChanged => "expectation-changed"
    BaselineActualChanged => "actual-changed"
    BaselinePassStatusChanged => "pass-status-changed"
    BaselineIssueCodesChanged => "issue-codes-changed"
  }
}

///|
pub fn BaselineChange::to_line(self : BaselineChange) -> String {
  self.impact.label() +
  "|" +
  self.kind.label() +
  "|" +
  self.case_name +
  "|before=" +
  self.before +
  "|after=" +
  self.after
}

///|
pub fn BaselineDiff::is_unchanged(self : BaselineDiff) -> Bool {
  self.changes.length() == 0
}

///|
pub fn BaselineDiff::regression_count(self : BaselineDiff) -> Int {
  self.count_impact(BaselineRegression)
}

///|
pub fn BaselineDiff::review_count(self : BaselineDiff) -> Int {
  self.count_impact(BaselineReview)
}

///|
pub fn BaselineDiff::compatible_count(self : BaselineDiff) -> Int {
  self.count_impact(BaselineCompatible)
}

///|
pub fn BaselineDiff::has_regressions(self : BaselineDiff) -> Bool {
  self.regression_count() > 0
}

///|
pub fn BaselineDiff::summary(self : BaselineDiff) -> String {
  "baseline-diff=" +
  self.suite_name +
  ", regressions=" +
  self.regression_count().to_string() +
  ", review=" +
  self.review_count().to_string() +
  ", compatible=" +
  self.compatible_count().to_string()
}

///|
pub fn BaselineDiff::to_lines(self : BaselineDiff) -> Array[String] {
  let lines = [self.summary()]
  let mut i = 0
  while i < self.changes.length() {
    lines.push(self.changes[i].to_line())
    i = i + 1
  }
  lines
}

///|
/// Render a Markdown behavior-diff report for CI artifacts and code review.
pub fn BaselineDiff::to_markdown(self : BaselineDiff) -> String {
  let lines = [
    "# Upload conformance baseline diff",
    "",
    self.summary(),
    "",
    "| Impact | Change | Case | Before | After |",
    "| --- | --- | --- | --- | --- |",
  ]
  if self.changes.length() == 0 {
    lines.push("| compatible | unchanged | - | - | - |")
  } else {
    let mut i = 0
    while i < self.changes.length() {
      let change = self.changes[i]
      lines.push(
        "| " +
        change.impact.label() +
        " | " +
        change.kind.label() +
        " | " +
        baseline_markdown_cell(change.case_name) +
        " | " +
        baseline_markdown_cell(change.before) +
        " | " +
        baseline_markdown_cell(change.after) +
        " |",
      )
      i = i + 1
    }
  }
  lines.join("\n")
}

///|
fn BaselineDiff::count_impact(
  self : BaselineDiff,
  impact : BaselineChangeImpact,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.changes.length() {
    if self.changes[i].impact == impact {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
fn baseline_compare_entry(
  previous : ConformanceBaselineEntry,
  current : ConformanceCaseResult,
  changes : Array[BaselineChange],
) -> Unit {
  if previous.expectation != current.expectation {
    changes.push({
      impact: BaselineReview,
      kind: BaselineExpectationChanged,
      case_name: previous.name,
      before: previous.expectation.label(),
      after: current.expectation.label(),
    })
  }
  if previous.actual != current.actual {
    changes.push({
      impact: BaselineRegression,
      kind: BaselineActualChanged,
      case_name: previous.name,
      before: previous.actual.label(),
      after: current.actual.label(),
    })
  }
  if previous.passed != current.passed {
    changes.push({
      impact: if previous.passed {
        BaselineRegression
      } else {
        BaselineCompatible
      },
      kind: BaselinePassStatusChanged,
      case_name: previous.name,
      before: baseline_pass_label(previous.passed),
      after: baseline_pass_label(current.passed),
    })
  }
  if !baseline_string_arrays_equal(previous.issue_codes, current.issue_codes) {
    changes.push({
      impact: BaselineReview,
      kind: BaselineIssueCodesChanged,
      case_name: previous.name,
      before: previous.issue_codes.join(","),
      after: current.issue_codes.join(","),
    })
  }
}

///|
fn baseline_serialize_entry(entry : ConformanceBaselineEntry) -> String {
  let escaped_codes = Array::new()
  let mut i = 0
  while i < entry.issue_codes.length() {
    escaped_codes.push(baseline_escape(entry.issue_codes[i]))
    i = i + 1
  }
  "case\t" +
  baseline_escape(entry.name) +
  "\t" +
  entry.expectation.label() +
  "\t" +
  entry.actual.label() +
  "\t" +
  baseline_pass_label(entry.passed) +
  "\t" +
  escaped_codes.join(",")
}

///|
fn baseline_parse_entry(
  line : String,
) -> Result[ConformanceBaselineEntry, BaselineError] {
  let fields = line.split("\t").collect()
  if fields.length() != 6 || fields[0] != "case" {
    return Err(InvalidBaselineLine(line))
  }
  let name = match baseline_unescape(fields[1].to_owned()) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let expectation = match baseline_parse_expectation(fields[2].to_owned()) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let actual = match baseline_parse_actual(fields[3].to_owned()) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let passed = match fields[4] {
    "pass" => true
    "fail" => false
    value => return Err(InvalidBaselineStatus(value.to_owned()))
  }
  let issue_codes = Array::new()
  if fields[5] != "" {
    let encoded_codes = fields[5].split(",").collect()
    let mut i = 0
    while i < encoded_codes.length() {
      match baseline_unescape(encoded_codes[i].to_owned()) {
        Ok(value) => issue_codes.push(value)
        Err(err) => return Err(err)
      }
      i = i + 1
    }
  }
  Ok({ name, expectation, actual, passed, issue_codes })
}

///|
fn baseline_parse_expectation(
  value : String,
) -> Result[ConformanceExpectation, BaselineError] {
  match value {
    "accepted" => Ok(ExpectAccepted)
    "rejected" => Ok(ExpectRejected)
    "parse-error" => Ok(ExpectParseError)
    _ => Err(InvalidBaselineExpectation(value))
  }
}

///|
fn baseline_parse_actual(
  value : String,
) -> Result[ConformanceActual, BaselineError] {
  match value {
    "accepted" => Ok(ActualAccepted)
    "rejected" => Ok(ActualRejected)
    "parse-error" => Ok(ActualParseError)
    _ => Err(InvalidBaselineActual(value))
  }
}

///|
fn baseline_entry_state(entry : ConformanceBaselineEntry) -> String {
  "expected=" +
  entry.expectation.label() +
  ",actual=" +
  entry.actual.label() +
  ",status=" +
  baseline_pass_label(entry.passed)
}

///|
fn baseline_result_state(result : ConformanceCaseResult) -> String {
  "expected=" +
  result.expectation.label() +
  ",actual=" +
  result.actual.label() +
  ",status=" +
  baseline_pass_label(result.passed)
}

///|
fn baseline_pass_label(passed : Bool) -> String {
  if passed {
    "pass"
  } else {
    "fail"
  }
}

///|
fn baseline_find_entry(
  entries : Array[ConformanceBaselineEntry],
  name : String,
) -> ConformanceBaselineEntry? {
  let mut i = 0
  while i < entries.length() {
    if entries[i].name == name {
      return Some(entries[i])
    }
    i = i + 1
  }
  None
}

///|
fn baseline_find_result(
  results : Array[ConformanceCaseResult],
  name : String,
) -> ConformanceCaseResult? {
  let mut i = 0
  while i < results.length() {
    if results[i].name == name {
      return Some(results[i])
    }
    i = i + 1
  }
  None
}

///|
fn baseline_string_arrays_equal(a : Array[String], b : Array[String]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut i = 0
  while i < a.length() {
    if a[i] != b[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn baseline_clone_strings(values : Array[String]) -> Array[String] {
  let copy = Array::new()
  let mut i = 0
  while i < values.length() {
    copy.push(values[i])
    i = i + 1
  }
  copy
}

///|
fn baseline_escape(value : String) -> String {
  let out = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let code = value.code_unit_at(i)
    if code == 37 {
      out.write_string("%25")
    } else if code == 9 {
      out.write_string("%09")
    } else if code == 10 {
      out.write_string("%0A")
    } else if code == 13 {
      out.write_string("%0D")
    } else if code == 44 {
      out.write_string("%2C")
    } else {
      out.write_char(code.unsafe_to_char())
    }
    i = i + 1
  }
  out.to_string()
}

///|
fn baseline_unescape(value : String) -> Result[String, BaselineError] {
  let out = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let code = value.code_unit_at(i)
    if code == 37 {
      if i + 2 >= value.length() {
        return Err(InvalidBaselineEscape(value))
      }
      let hi = baseline_hex_value(value.code_unit_at(i + 1))
      let lo = baseline_hex_value(value.code_unit_at(i + 2))
      if hi < 0 || lo < 0 {
        return Err(InvalidBaselineEscape(value))
      }
      out.write_char((hi * 16 + lo).unsafe_to_char())
      i = i + 3
    } else {
      out.write_char(code.unsafe_to_char())
      i = i + 1
    }
  }
  Ok(out.to_string())
}

///|
fn baseline_hex_value(code : UInt16) -> Int {
  if code >= 48 && code <= 57 {
    code.to_int() - 48
  } else if code >= 65 && code <= 70 {
    code.to_int() - 55
  } else if code >= 97 && code <= 102 {
    code.to_int() - 87
  } else {
    -1
  }
}

///|
fn baseline_markdown_cell(value : String) -> String {
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
