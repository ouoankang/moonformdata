///|
fn catalog_contract(required_name : String) -> @moonformdata.UploadContract {
  @moonformdata.upload_contract(
    @moonformdata.strict_form_schema().add_field_rule(
      @moonformdata.required_field_rule(required_name),
    ),
  )
}

///|
fn catalog_endpoint(
  id : String,
  http_method : String,
  path : String,
  required_name : String,
) -> @moonformdata.UploadEndpoint {
  @moonformdata.upload_endpoint(
    id,
    http_method,
    path,
    "1.0.0",
    catalog_contract(required_name),
  ).unwrap()
}

///|
test "upload catalog normalizes methods and finds routes" {
  let endpoint = catalog_endpoint("avatar", "post", "/v1/avatar", "user_id")
  let catalog = @moonformdata.upload_contract_catalog().add(endpoint).unwrap()
  debug_inspect(catalog.endpoint_count(), content="1")
  debug_inspect(
    catalog.find_route("POST", "/v1/avatar") is Some(_),
    content="true",
  )
  debug_inspect(
    catalog.find_route("post", "/v1/avatar") is Some(_),
    content="true",
  )
  debug_inspect(catalog.find_by_id("avatar") is Some(_), content="true")
}

///|
test "upload catalog validates endpoint metadata" {
  let contract = catalog_contract("id")
  debug_inspect(
    @moonformdata.upload_endpoint("", "POST", "/upload", "1", contract),
    content="Err(InvalidEndpointId(\"\"))",
  )
  debug_inspect(
    @moonformdata.upload_endpoint("bad", "POST 2", "/upload", "1", contract),
    content="Err(InvalidEndpointMethod(\"POST 2\"))",
  )
  debug_inspect(
    @moonformdata.upload_endpoint("bad", "POST", "upload", "1", contract),
    content="Err(InvalidEndpointPath(\"upload\"))",
  )
}

///|
test "upload catalog rejects duplicate ids and routes" {
  let first = catalog_endpoint("avatar", "POST", "/avatar", "user_id")
  let catalog = @moonformdata.upload_contract_catalog().add(first).unwrap()
  let duplicate_id = catalog_endpoint("avatar", "POST", "/other", "id")
  let duplicate_route = catalog_endpoint("other", "post", "/avatar", "id")
  debug_inspect(
    catalog.add(duplicate_id),
    content="Err(DuplicateEndpointId(\"avatar\"))",
  )
  debug_inspect(
    catalog.add(duplicate_route),
    content="Err(DuplicateEndpointRoute(\"POST /avatar\"))",
  )
}

///|
test "upload catalog routes and inspects a request" {
  let catalog = @moonformdata.upload_contract_catalog()
    .add(catalog_endpoint("avatar", "POST", "/avatar", "user_id"))
    .unwrap()
  let request = @moonformdata.build_request_from_fields(
    [("user_id", "42")],
    boundary="catalog-route",
  ).unwrap()
  match catalog.inspect_route("post", "/avatar", request) {
    Ok(result) => {
      debug_inspect(result.endpoint_id, content="\"avatar\"")
      debug_inspect(result.inspection.is_accepted(), content="true")
      debug_inspect(
        result.decision_line().has_prefix("endpoint=avatar@1.0.0"),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "upload catalog distinguishes missing routes" {
  let catalog = @moonformdata.upload_contract_catalog()
  let request = @moonformdata.build_request_from_fields(
    [("id", "1")],
    boundary="catalog-missing",
  ).unwrap()
  match catalog.inspect_route("POST", "/missing", request) {
    Ok(_) => fail("expected missing route")
    Err(err) =>
      debug_inspect(
        err.message(),
        content="\"upload endpoint not found: POST /missing\"",
      )
  }
}

///|
test "catalog conformance runs suites for multiple endpoints" {
  let catalog = @moonformdata.upload_contract_catalog()
    .add(catalog_endpoint("avatar", "POST", "/avatar", "user_id"))
    .unwrap()
    .add(catalog_endpoint("document", "POST", "/document", "document_id"))
    .unwrap()
  let avatar_request = @moonformdata.build_request_from_fields(
    [("user_id", "42")],
    boundary="catalog-avatar",
  ).unwrap()
  let document_request = @moonformdata.build_request_from_fields(
    [("document_id", "doc-1")],
    boundary="catalog-document",
  ).unwrap()
  let plans = [
    @moonformdata.endpoint_conformance_plan("avatar", "smoke", [
      @moonformdata.upload_conformance_case(
        "avatar accepted",
        avatar_request,
        @moonformdata.ExpectAccepted,
      ),
    ]),
    @moonformdata.endpoint_conformance_plan("document", "smoke", [
      @moonformdata.upload_conformance_case(
        "document accepted",
        document_request,
        @moonformdata.ExpectAccepted,
      ),
    ]),
  ]
  let report = @moonformdata.run_catalog_conformance("api-v1", catalog, plans)
  debug_inspect(report.is_ok(), content="true")
  debug_inspect(report.case_count(), content="2")
  debug_inspect(report.passed_count(), content="2")
}

///|
test "catalog conformance reports missing endpoints and duplicate suites" {
  let catalog = @moonformdata.upload_contract_catalog()
  let plan = @moonformdata.endpoint_conformance_plan("missing", "smoke", [])
  let report = @moonformdata.run_catalog_conformance("invalid", catalog, [
    plan, plan,
  ])
  debug_inspect(report.is_ok(), content="false")
  debug_inspect(report.suites.length(), content="0")
  debug_inspect(report.issues.length(), content="2")
  debug_inspect(report.failed_count(), content="2")
}

///|
test "catalog and conformance reports render deterministic markdown" {
  let catalog = @moonformdata.upload_contract_catalog()
    .add(catalog_endpoint("avatar", "POST", "/avatar", "user_id"))
    .unwrap()
  let request = @moonformdata.build_request_from_fields(
    [("user_id", "42")],
    boundary="catalog-markdown",
  ).unwrap()
  let report = @moonformdata.run_catalog_conformance("api|v1", catalog, [
    @moonformdata.endpoint_conformance_plan("avatar", "smoke", [
      @moonformdata.upload_conformance_case(
        "accepted",
        request,
        @moonformdata.ExpectAccepted,
      ),
    ]),
  ])
  debug_inspect(catalog.to_lines().length(), content="2")
  debug_inspect(
    report.to_markdown().find("api\\|v1") is Some(_),
    content="true",
  )
  debug_inspect(
    report.to_markdown().find("avatar@1.0.0/smoke") is Some(_),
    content="true",
  )
}
