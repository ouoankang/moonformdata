///|
/// Final decision produced by an upload contract inspection.
pub(all) enum UploadDecision {
  UploadAccepted
  UploadRejected
} derive(Debug, Eq)

///|
/// Application-facing multipart contract.
///
/// A contract combines parser limits, a named form schema, and the highest
/// analysis risk accepted by an endpoint.
pub(all) struct UploadContract {
  parse_options : ParseOptions
  schema : FormSchema
  max_risk : UploadRisk
} derive(Debug, Eq)

///|
/// Complete result of parsing and checking one upload request.
pub(all) struct UploadInspection {
  form : MultipartForm
  validation : ValidationReport
  analysis : FormAnalysis
  max_risk : UploadRisk
  decision : UploadDecision
} derive(Debug, Eq)

///|
/// Create a contract with conservative parser limits and a medium risk ceiling.
pub fn upload_contract(schema : FormSchema) -> UploadContract {
  { parse_options: default_parse_options(), schema, max_risk: MediumRisk }
}

///|
/// Replace the parser limits used by a contract.
pub fn UploadContract::with_parse_options(
  self : UploadContract,
  parse_options : ParseOptions,
) -> UploadContract {
  { parse_options, schema: self.schema, max_risk: self.max_risk }
}

///|
/// Replace the declarative form schema used by a contract.
pub fn UploadContract::with_schema(
  self : UploadContract,
  schema : FormSchema,
) -> UploadContract {
  { parse_options: self.parse_options, schema, max_risk: self.max_risk }
}

///|
/// Set the highest analysis risk accepted by a contract.
pub fn UploadContract::with_max_risk(
  self : UploadContract,
  max_risk : UploadRisk,
) -> UploadContract {
  { parse_options: self.parse_options, schema: self.schema, max_risk }
}

///|
/// Parse and inspect a request using one application-facing upload contract.
pub fn inspect_upload_request(
  request : MultipartRequest,
  contract : UploadContract,
) -> Result[UploadInspection, MultipartError] {
  inspect_upload(request.content_type, request.body, contract)
}

///|
/// Parse and inspect a raw multipart request using one upload contract.
pub fn inspect_upload(
  content_type : String,
  body : String,
  contract : UploadContract,
) -> Result[UploadInspection, MultipartError] {
  match
    parse_multipart_request_with_options(
      content_type,
      body,
      contract.parse_options,
    ) {
    Ok(form) => Ok(inspect_parsed_form(form, contract))
    Err(err) => Err(err)
  }
}

///|
/// Inspect an already parsed form without parsing it again.
pub fn inspect_parsed_form(
  form : MultipartForm,
  contract : UploadContract,
) -> UploadInspection {
  let validation = form.validate_schema(contract.schema)
  let analysis = analyze_form(form)
  let decision = if validation.is_ok() &&
    upload_risk_at_most(analysis.risk, contract.max_risk) {
    UploadAccepted
  } else {
    UploadRejected
  }
  { form, validation, analysis, max_risk: contract.max_risk, decision }
}

///|
pub fn UploadDecision::label(self : UploadDecision) -> String {
  match self {
    UploadAccepted => "accepted"
    UploadRejected => "rejected"
  }
}

///|
pub fn UploadInspection::is_accepted(self : UploadInspection) -> Bool {
  self.decision == UploadAccepted
}

///|
/// A conventional status code for endpoint adapters.
pub fn UploadInspection::status_code(self : UploadInspection) -> Int {
  if self.is_accepted() {
    200
  } else {
    422
  }
}

///|
/// Stable one-line result for logs, CI output, and webhook diagnostics.
pub fn UploadInspection::decision_line(self : UploadInspection) -> String {
  "decision=" +
  self.decision.label() +
  ", risk=" +
  self.analysis.risk.label() +
  ", max_risk=" +
  self.max_risk.label() +
  ", validation_issues=" +
  self.validation.issue_count().to_string() +
  ", parts=" +
  self.form.part_count().to_string()
}

///|
/// Explain every reason why an otherwise parseable request was rejected.
pub fn UploadInspection::rejection_reasons(
  self : UploadInspection,
) -> Array[String] {
  let reasons = Array::new()
  if !self.validation.is_ok() {
    let validation_lines = self.validation.to_lines()
    let mut i = 0
    while i < validation_lines.length() {
      reasons.push(validation_lines[i])
      i = i + 1
    }
  }
  if !upload_risk_at_most(self.analysis.risk, self.max_risk) {
    reasons.push(
      "upload risk " +
      self.analysis.risk.label() +
      " exceeds contract limit " +
      self.max_risk.label(),
    )
  }
  reasons
}

///|
/// Render a deterministic inspection report.
pub fn UploadInspection::to_lines(self : UploadInspection) -> Array[String] {
  let lines = Array::new()
  lines.push(self.decision_line())
  let reasons = self.rejection_reasons()
  let mut i = 0
  while i < reasons.length() {
    lines.push("reason: " + reasons[i])
    i = i + 1
  }
  let analysis_lines = self.analysis.to_lines()
  let mut j = 0
  while j < analysis_lines.length() {
    lines.push("analysis: " + analysis_lines[j])
    j = j + 1
  }
  lines
}

///|
pub fn upload_risk_at_most(actual : UploadRisk, maximum : UploadRisk) -> Bool {
  upload_risk_rank(actual) <= upload_risk_rank(maximum)
}

///|
fn upload_risk_rank(risk : UploadRisk) -> Int {
  match risk {
    LowRisk => 1
    MediumRisk => 2
    HighRisk => 3
  }
}
