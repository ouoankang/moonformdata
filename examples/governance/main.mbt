///|
fn avatar_schema(required_title : Bool) -> @moonformdata.FormSchema {
  let title_rule = @moonformdata.field_rule("title")
    .with_required(required_title)
    .with_max_values(1)
    .with_max_length(80)
  @moonformdata.strict_form_schema()
  .add_field_rule(title_rule)
  .add_file_rule(
    @moonformdata.required_file_rule("avatar")
    .with_max_files(1)
    .with_max_length(1024 * 1024)
    .with_allow_empty(false)
    .allow_content_type("image/png")
    .allow_extension("png"),
  )
}

///|
fn request_with_title() -> @moonformdata.MultipartRequest {
  @moonformdata.build_upload_request(
    [("title", "profile")],
    [@moonformdata.file_spec("avatar", "avatar.png", "image/png", "PNG")],
    boundary="governance-valid",
  ).unwrap()
}

///|
fn request_without_title() -> @moonformdata.MultipartRequest {
  @moonformdata.build_upload_request(
    [],
    [@moonformdata.file_spec("avatar", "avatar.png", "image/png", "PNG")],
    boundary="governance-missing",
  ).unwrap()
}

///|
fn main {
  let v1 = @moonformdata.upload_contract(avatar_schema(false)).with_max_risk(
    @moonformdata.LowRisk,
  )
  let v2 = @moonformdata.upload_contract(avatar_schema(true)).with_max_risk(
    @moonformdata.LowRisk,
  )

  let compatibility = @moonformdata.compare_upload_contracts(v1, v2)
  println(compatibility.summary())
  for line in compatibility.to_lines() {
    println(line)
  }

  let cases = [
    @moonformdata.upload_conformance_case(
      "valid avatar",
      request_with_title(),
      @moonformdata.ExpectAccepted,
    ).with_expected_risk(@moonformdata.LowRisk),
    @moonformdata.upload_conformance_case(
      "missing title",
      request_without_title(),
      @moonformdata.ExpectRejected,
    ).require_issue_code("schema_missing_field"),
  ]
  let suite = @moonformdata.run_conformance_suite("avatar-v2", v2, cases)
  println(suite.summary())

  let baseline = @moonformdata.conformance_baseline(suite)
  match @moonformdata.parse_conformance_baseline(baseline.to_text()) {
    Ok(parsed) => {
      let rerun = @moonformdata.run_conformance_suite("avatar-v2", v2, [
        @moonformdata.upload_conformance_case(
          "valid avatar",
          request_with_title(),
          @moonformdata.ExpectAccepted,
        ).with_expected_risk(@moonformdata.LowRisk),
        @moonformdata.upload_conformance_case(
          "missing title",
          request_without_title(),
          @moonformdata.ExpectRejected,
        ).require_issue_code("schema_missing_field"),
      ])
      println(
        @moonformdata.compare_conformance_baseline(parsed, rerun).summary(),
      )
    }
    Err(err) => println(err.message())
  }

  let endpoint = @moonformdata.upload_endpoint(
    "avatar-upload", "POST", "/v2/avatar", "2.0.0", v2,
  ).unwrap()
  let catalog = @moonformdata.upload_contract_catalog().add(endpoint).unwrap()
  match catalog.inspect_route("post", "/v2/avatar", request_with_title()) {
    Ok(result) => println(result.decision_line())
    Err(err) => println(err.message())
  }
}
