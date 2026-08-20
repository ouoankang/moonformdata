///|
/// Validation and lookup errors produced by an upload contract catalog.
pub(all) enum CatalogError {
  InvalidEndpointId(String)
  InvalidEndpointMethod(String)
  InvalidEndpointPath(String)
  InvalidEndpointVersion(String)
  DuplicateEndpointId(String)
  DuplicateEndpointRoute(String)
  EndpointNotFound(String)
} derive(Debug, Eq)

///|
/// Request inspection errors distinguish routing failures from multipart failures.
pub(all) enum CatalogInspectionError {
  CatalogRoutingError(CatalogError)
  CatalogUploadError(MultipartError)
} derive(Debug, Eq)

///|
/// One versioned upload endpoint and its application-facing contract.
pub(all) struct UploadEndpoint {
  id : String
  http_method : String
  path : String
  version : String
  contract : UploadContract
} derive(Debug, Eq)

///|
/// Immutable-style collection of upload endpoint contracts.
pub(all) struct UploadContractCatalog {
  endpoints : Array[UploadEndpoint]
} derive(Debug, Eq)

///|
/// Successful routed inspection with endpoint identity preserved.
pub(all) struct CatalogInspection {
  endpoint_id : String
  endpoint_version : String
  inspection : UploadInspection
} derive(Debug, Eq)

///|
/// Named conformance suite assigned to one catalog endpoint.
pub(all) struct EndpointConformancePlan {
  endpoint_id : String
  suite_name : String
  cases : Array[UploadConformanceCase]
} derive(Debug, Eq)

///|
/// Multi-endpoint conformance result for CI and API governance.
pub(all) struct CatalogConformanceReport {
  catalog_name : String
  suites : Array[ConformanceSuiteResult]
  issues : Array[String]
} derive(Debug, Eq)

///|
/// Create and validate one endpoint catalog entry.
pub fn upload_endpoint(
  id : String,
  http_method : String,
  path : String,
  version : String,
  contract : UploadContract,
) -> Result[UploadEndpoint, CatalogError] {
  let normalized_id = trim_ascii(id)
  let normalized_method = catalog_upper_ascii(trim_ascii(http_method))
  let normalized_path = trim_ascii(path)
  let normalized_version = trim_ascii(version)
  if normalized_id == "" {
    return Err(InvalidEndpointId(id))
  }
  if !catalog_valid_method(normalized_method) {
    return Err(InvalidEndpointMethod(http_method))
  }
  if !catalog_valid_path(normalized_path) {
    return Err(InvalidEndpointPath(path))
  }
  if normalized_version == "" {
    return Err(InvalidEndpointVersion(version))
  }
  Ok({
    id: normalized_id,
    http_method: normalized_method,
    path: normalized_path,
    version: normalized_version,
    contract,
  })
}

///|
/// Create an empty upload contract catalog.
pub fn upload_contract_catalog() -> UploadContractCatalog {
  { endpoints: [] }
}

///|
/// Add one endpoint while rejecting duplicate IDs and routes.
pub fn UploadContractCatalog::add(
  self : UploadContractCatalog,
  endpoint : UploadEndpoint,
) -> Result[UploadContractCatalog, CatalogError] {
  let mut i = 0
  while i < self.endpoints.length() {
    if self.endpoints[i].id == endpoint.id {
      return Err(DuplicateEndpointId(endpoint.id))
    }
    if self.endpoints[i].http_method == endpoint.http_method &&
      self.endpoints[i].path == endpoint.path {
      return Err(
        DuplicateEndpointRoute(endpoint.http_method + " " + endpoint.path),
      )
    }
    i = i + 1
  }
  let endpoints = catalog_clone_endpoints(self.endpoints)
  endpoints.push(endpoint)
  Ok({ endpoints, })
}

///|
/// Return an endpoint by stable catalog ID.
pub fn UploadContractCatalog::find_by_id(
  self : UploadContractCatalog,
  id : String,
) -> UploadEndpoint? {
  let normalized = trim_ascii(id)
  let mut i = 0
  while i < self.endpoints.length() {
    if self.endpoints[i].id == normalized {
      return Some(self.endpoints[i])
    }
    i = i + 1
  }
  None
}

///|
/// Return an endpoint by normalized HTTP method and exact path.
pub fn UploadContractCatalog::find_route(
  self : UploadContractCatalog,
  http_method : String,
  path : String,
) -> UploadEndpoint? {
  let normalized_method = catalog_upper_ascii(trim_ascii(http_method))
  let normalized_path = trim_ascii(path)
  let mut i = 0
  while i < self.endpoints.length() {
    if self.endpoints[i].http_method == normalized_method &&
      self.endpoints[i].path == normalized_path {
      return Some(self.endpoints[i])
    }
    i = i + 1
  }
  None
}

///|
/// Route and inspect a multipart request using the matching endpoint contract.
pub fn UploadContractCatalog::inspect_route(
  self : UploadContractCatalog,
  http_method : String,
  path : String,
  request : MultipartRequest,
) -> Result[CatalogInspection, CatalogInspectionError] {
  match self.find_route(http_method, path) {
    Some(endpoint) =>
      match inspect_upload_request(request, endpoint.contract) {
        Ok(inspection) =>
          Ok({
            endpoint_id: endpoint.id,
            endpoint_version: endpoint.version,
            inspection,
          })
        Err(err) => Err(CatalogUploadError(err))
      }
    None =>
      Err(
        CatalogRoutingError(
          EndpointNotFound(
            catalog_upper_ascii(trim_ascii(http_method)) +
            " " +
            trim_ascii(path),
          ),
        ),
      )
  }
}

///|
/// Create a conformance plan for one endpoint ID.
pub fn endpoint_conformance_plan(
  endpoint_id : String,
  suite_name : String,
  cases : Array[UploadConformanceCase],
) -> EndpointConformancePlan {
  {
    endpoint_id: trim_ascii(endpoint_id),
    suite_name: trim_ascii(suite_name),
    cases: catalog_clone_cases(cases),
  }
}

///|
/// Run conformance plans against every referenced endpoint in a catalog.
pub fn run_catalog_conformance(
  catalog_name : String,
  catalog : UploadContractCatalog,
  plans : Array[EndpointConformancePlan],
) -> CatalogConformanceReport {
  let suites = Array::new()
  let issues = Array::new()
  let suite_keys : Array[String] = []
  let mut i = 0
  while i < plans.length() {
    let plan = plans[i]
    let suite_key = plan.endpoint_id + ":" + plan.suite_name
    if catalog_string_contains(suite_keys, suite_key) {
      issues.push("duplicate endpoint suite: " + suite_key)
    } else {
      suite_keys.push(suite_key)
      match catalog.find_by_id(plan.endpoint_id) {
        Some(endpoint) =>
          suites.push(
            run_conformance_suite(
              endpoint.id + "@" + endpoint.version + "/" + plan.suite_name,
              endpoint.contract,
              plan.cases,
            ),
          )
        None => issues.push("endpoint not found for suite: " + plan.endpoint_id)
      }
    }
    i = i + 1
  }
  { catalog_name: trim_ascii(catalog_name), suites, issues }
}

///|
pub fn CatalogError::message(self : CatalogError) -> String {
  match self {
    InvalidEndpointId(value) => "invalid endpoint id: " + value
    InvalidEndpointMethod(value) => "invalid endpoint method: " + value
    InvalidEndpointPath(value) => "invalid endpoint path: " + value
    InvalidEndpointVersion(value) => "invalid endpoint version: " + value
    DuplicateEndpointId(value) => "duplicate endpoint id: " + value
    DuplicateEndpointRoute(value) => "duplicate endpoint route: " + value
    EndpointNotFound(value) => "upload endpoint not found: " + value
  }
}

///|
pub fn CatalogInspectionError::message(self : CatalogInspectionError) -> String {
  match self {
    CatalogRoutingError(err) => err.message()
    CatalogUploadError(err) => err.message()
  }
}

///|
pub fn UploadEndpoint::route_key(self : UploadEndpoint) -> String {
  self.http_method + " " + self.path
}

///|
pub fn UploadEndpoint::label(self : UploadEndpoint) -> String {
  self.id + "@" + self.version + " (" + self.route_key() + ")"
}

///|
pub fn UploadContractCatalog::endpoint_count(
  self : UploadContractCatalog,
) -> Int {
  self.endpoints.length()
}

///|
pub fn UploadContractCatalog::to_lines(
  self : UploadContractCatalog,
) -> Array[String] {
  let lines = [
    "upload-contract-catalog: endpoints=" + self.endpoints.length().to_string(),
  ]
  let mut i = 0
  while i < self.endpoints.length() {
    lines.push(self.endpoints[i].label())
    i = i + 1
  }
  lines
}

///|
pub fn CatalogInspection::decision_line(self : CatalogInspection) -> String {
  "endpoint=" +
  self.endpoint_id +
  "@" +
  self.endpoint_version +
  ", " +
  self.inspection.decision_line()
}

///|
pub fn CatalogConformanceReport::passed_count(
  self : CatalogConformanceReport,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.suites.length() {
    count = count + self.suites[i].passed_count()
    i = i + 1
  }
  count
}

///|
pub fn CatalogConformanceReport::failed_count(
  self : CatalogConformanceReport,
) -> Int {
  let mut count = self.issues.length()
  let mut i = 0
  while i < self.suites.length() {
    count = count + self.suites[i].failed_count()
    i = i + 1
  }
  count
}

///|
pub fn CatalogConformanceReport::case_count(
  self : CatalogConformanceReport,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.suites.length() {
    count = count + self.suites[i].cases.length()
    i = i + 1
  }
  count
}

///|
pub fn CatalogConformanceReport::is_ok(self : CatalogConformanceReport) -> Bool {
  self.failed_count() == 0
}

///|
pub fn CatalogConformanceReport::summary(
  self : CatalogConformanceReport,
) -> String {
  "catalog-conformance=" +
  self.catalog_name +
  ", suites=" +
  self.suites.length().to_string() +
  ", cases=" +
  self.case_count().to_string() +
  ", passed=" +
  self.passed_count().to_string() +
  ", failed=" +
  self.failed_count().to_string()
}

///|
/// Render a multi-endpoint Markdown conformance matrix.
pub fn CatalogConformanceReport::to_markdown(
  self : CatalogConformanceReport,
) -> String {
  let lines = [
    "# Upload catalog conformance: " + catalog_markdown_cell(self.catalog_name),
    "",
    self.summary(),
    "",
    "| Suite | Cases | Passed | Failed | Status |",
    "| --- | ---: | ---: | ---: | --- |",
  ]
  let mut i = 0
  while i < self.suites.length() {
    let suite = self.suites[i]
    let status = if suite.is_ok() { "pass" } else { "fail" }
    lines.push(
      "| " +
      catalog_markdown_cell(suite.name) +
      " | " +
      suite.cases.length().to_string() +
      " | " +
      suite.passed_count().to_string() +
      " | " +
      suite.failed_count().to_string() +
      " | " +
      status +
      " |",
    )
    i = i + 1
  }
  if self.issues.length() > 0 {
    lines.push("")
    lines.push("## Catalog issues")
    lines.push("")
    let mut j = 0
    while j < self.issues.length() {
      lines.push("- " + self.issues[j])
      j = j + 1
    }
  }
  lines.join("\n")
}

///|
fn catalog_valid_method(value : String) -> Bool {
  if value == "" {
    return false
  }
  let mut i = 0
  while i < value.length() {
    let code = value.code_unit_at(i)
    if code < 65 || code > 90 {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn catalog_valid_path(value : String) -> Bool {
  if value == "" || !value.has_prefix("/") {
    return false
  }
  value.find("?") is None && value.find("#") is None && value.find(" ") is None
}

///|
fn catalog_upper_ascii(value : String) -> String {
  let out = StringBuilder::new()
  let mut i = 0
  while i < value.length() {
    let code = value.code_unit_at(i)
    if code >= 97 && code <= 122 {
      out.write_char((code.to_int() - 32).unsafe_to_char())
    } else {
      out.write_char(code.unsafe_to_char())
    }
    i = i + 1
  }
  out.to_string()
}

///|
fn catalog_clone_endpoints(
  endpoints : Array[UploadEndpoint],
) -> Array[UploadEndpoint] {
  let copy = Array::new()
  let mut i = 0
  while i < endpoints.length() {
    copy.push(endpoints[i])
    i = i + 1
  }
  copy
}

///|
fn catalog_clone_cases(
  cases : Array[UploadConformanceCase],
) -> Array[UploadConformanceCase] {
  let copy = Array::new()
  let mut i = 0
  while i < cases.length() {
    copy.push(cases[i])
    i = i + 1
  }
  copy
}

///|
fn catalog_string_contains(values : Array[String], target : String) -> Bool {
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
fn catalog_markdown_cell(value : String) -> String {
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
