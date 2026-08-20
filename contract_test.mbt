///|
fn upload_contract_schema() -> @moonformdata.FormSchema {
  @moonformdata.strict_form_schema()
  .add_field_rule(
    @moonformdata.required_field_rule("title")
    .with_max_values(1)
    .with_max_length(80),
  )
  .add_file_rule(
    @moonformdata.required_file_rule("upload")
    .with_max_files(1)
    .with_max_length(32)
    .allow_content_type("text/plain")
    .allow_extension("txt"),
  )
}

///|
fn accepted_upload_request() -> @moonformdata.MultipartRequest {
  @moonformdata.build_upload_request(
    [("title", "contract demo")],
    [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
    boundary="contract-ok",
  ).unwrap()
}

///|
test "upload contract accepts a valid endpoint request" {
  let contract = @moonformdata.upload_contract(upload_contract_schema()).with_max_risk(
    @moonformdata.LowRisk,
  )
  match
    @moonformdata.inspect_upload_request(accepted_upload_request(), contract) {
    Ok(inspection) => {
      debug_inspect(inspection.is_accepted(), content="true")
      debug_inspect(inspection.status_code(), content="200")
      debug_inspect(
        inspection.decision_line(),
        content="\"decision=accepted, risk=low, max_risk=low, validation_issues=0, parts=2\"",
      )
      debug_inspect(inspection.rejection_reasons().length(), content="0")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "upload contract rejects a missing required field" {
  let request = match
    @moonformdata.build_upload_request(
      [],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="contract-missing",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let contract = @moonformdata.upload_contract(upload_contract_schema())
  match @moonformdata.inspect_upload_request(request, contract) {
    Ok(inspection) => {
      debug_inspect(inspection.is_accepted(), content="false")
      debug_inspect(inspection.status_code(), content="422")
      debug_inspect(
        inspection.validation.has_issue_code("schema_missing_field"),
        content="true",
      )
      debug_inspect(inspection.rejection_reasons().length(), content="1")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "upload contract rejects unknown form entries" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo"), ("unexpected", "value")],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="contract-unknown",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let contract = @moonformdata.upload_contract(upload_contract_schema())
  match @moonformdata.inspect_upload_request(request, contract) {
    Ok(inspection) => {
      debug_inspect(inspection.is_accepted(), content="false")
      debug_inspect(
        inspection.validation.has_issue_code("schema_unknown_field"),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "upload contract rejects high risk executable payload" {
  let request = match
    @moonformdata.build_upload_request(
      [],
      [
        @moonformdata.file_spec(
          "payload", "run.exe", "application/octet-stream", "MZ",
        ),
      ],
      boundary="contract-risk",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let contract = @moonformdata.upload_contract(
    @moonformdata.default_form_schema(),
  )
  match @moonformdata.inspect_upload_request(request, contract) {
    Ok(inspection) => {
      debug_inspect(inspection.analysis.risk, content="HighRisk")
      debug_inspect(inspection.is_accepted(), content="false")
      debug_inspect(inspection.rejection_reasons().length(), content="1")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "upload contract can explicitly allow high risk diagnostics" {
  let request = match
    @moonformdata.build_upload_request(
      [],
      [
        @moonformdata.file_spec(
          "payload", "run.exe", "application/octet-stream", "MZ",
        ),
      ],
      boundary="contract-risk-allowed",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let contract = @moonformdata.upload_contract(
    @moonformdata.default_form_schema(),
  ).with_max_risk(@moonformdata.HighRisk)
  match @moonformdata.inspect_upload_request(request, contract) {
    Ok(inspection) => debug_inspect(inspection.is_accepted(), content="true")
    Err(err) => fail(err.message())
  }
}

///|
test "upload contract enforces parser limits before schema validation" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("first", "1"), ("second", "2")],
      boundary="contract-limit",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let options : @moonformdata.ParseOptions = {
    max_parts: 1,
    max_headers_per_part: 8,
    max_body_length: 1024,
  }
  let contract = @moonformdata.upload_contract(
    @moonformdata.default_form_schema(),
  ).with_parse_options(options)
  debug_inspect(
    @moonformdata.inspect_upload_request(request, contract),
    content="Err(LimitExceeded(\"part count exceeds ParseOptions.max_parts\"))",
  )
}

///|
test "upload inspection emits deterministic report lines" {
  let contract = @moonformdata.upload_contract(upload_contract_schema())
  match
    @moonformdata.inspect_upload_request(accepted_upload_request(), contract) {
    Ok(inspection) => {
      let lines = inspection.to_lines()
      debug_inspect(lines.length() >= 2, content="true")
      debug_inspect(
        lines[0],
        content="\"decision=accepted, risk=low, max_risk=medium, validation_issues=0, parts=2\"",
      )
      debug_inspect(lines[1].has_prefix("analysis: "), content="true")
    }
    Err(err) => fail(err.message())
  }
}
