///|
pub(all) struct FileSpec {
  name : String
  filename : String
  content_type : String
  body : String
} derive(Debug, Eq)

///|
pub(all) struct MultipartRequest {
  content_type : String
  body : String
} derive(Debug, Eq)

///|
pub(all) struct ParseAndValidateResult {
  form : MultipartForm
  report : ValidationReport
} derive(Debug, Eq)

///|
pub fn file_spec(
  name : String,
  filename : String,
  content_type : String,
  body : String,
) -> FileSpec {
  { name, filename: safe_filename(filename), content_type, body }
}

///|
pub fn text_file_spec(
  name : String,
  filename : String,
  body : String,
) -> FileSpec {
  file_spec(name, filename, "text/plain", body)
}

///|
pub fn binary_file_spec(
  name : String,
  filename : String,
  body : String,
) -> FileSpec {
  file_spec(name, filename, "application/octet-stream", body)
}

///|
pub fn parse_multipart_request(
  content_type : String,
  body : String,
) -> Result[MultipartForm, MultipartError] {
  match boundary_from_content_type(content_type) {
    Ok(boundary) => parse_multipart(body, boundary)
    Err(err) => Err(err)
  }
}

///|
pub fn parse_multipart_request_with_options(
  content_type : String,
  body : String,
  options : ParseOptions,
) -> Result[MultipartForm, MultipartError] {
  match boundary_from_content_type(content_type) {
    Ok(boundary) => parse_multipart_with_options(body, boundary, options)
    Err(err) => Err(err)
  }
}

///|
pub fn encode_fields(
  fields : Array[(String, String)],
  boundary? : String,
) -> Result[EncodedForm, MultipartError] {
  let parts = Array::new()
  let mut i = 0
  while i < fields.length() {
    let (name, value) = fields[i]
    parts.push(text_part(name, value))
    i = i + 1
  }
  match boundary {
    Some(value) => encode_multipart(parts, boundary=value)
    None => encode_multipart(parts)
  }
}

///|
pub fn encode_files(
  files : Array[FileSpec],
  boundary? : String,
) -> Result[EncodedForm, MultipartError] {
  let parts = Array::new()
  let mut i = 0
  while i < files.length() {
    let file = files[i]
    parts.push(
      file_part(
        file.name,
        file.filename,
        file.body,
        content_type=file.content_type,
      ),
    )
    i = i + 1
  }
  match boundary {
    Some(value) => encode_multipart(parts, boundary=value)
    None => encode_multipart(parts)
  }
}

///|
pub fn encode_fields_and_files(
  fields : Array[(String, String)],
  files : Array[FileSpec],
  boundary? : String,
) -> Result[EncodedForm, MultipartError] {
  let parts = Array::new()
  let mut i = 0
  while i < fields.length() {
    let (name, value) = fields[i]
    parts.push(text_part(name, value))
    i = i + 1
  }
  let mut j = 0
  while j < files.length() {
    let file = files[j]
    parts.push(
      file_part(
        file.name,
        file.filename,
        file.body,
        content_type=file.content_type,
      ),
    )
    j = j + 1
  }
  match boundary {
    Some(value) => encode_multipart(parts, boundary=value)
    None => encode_multipart(parts)
  }
}

///|
pub fn encoded_to_request(encoded : EncodedForm) -> MultipartRequest {
  { content_type: encoded.content_type, body: encoded.body }
}

///|
pub fn build_request_from_fields(
  fields : Array[(String, String)],
  boundary? : String,
) -> Result[MultipartRequest, MultipartError] {
  match boundary {
    Some(value) =>
      match encode_fields(fields, boundary=value) {
        Ok(encoded) => Ok(encoded_to_request(encoded))
        Err(err) => Err(err)
      }
    None =>
      match encode_fields(fields) {
        Ok(encoded) => Ok(encoded_to_request(encoded))
        Err(err) => Err(err)
      }
  }
}

///|
pub fn build_upload_request(
  fields : Array[(String, String)],
  files : Array[FileSpec],
  boundary? : String,
) -> Result[MultipartRequest, MultipartError] {
  match boundary {
    Some(value) =>
      match encode_fields_and_files(fields, files, boundary=value) {
        Ok(encoded) => Ok(encoded_to_request(encoded))
        Err(err) => Err(err)
      }
    None =>
      match encode_fields_and_files(fields, files) {
        Ok(encoded) => Ok(encoded_to_request(encoded))
        Err(err) => Err(err)
      }
  }
}

///|
pub fn roundtrip_request(
  request : MultipartRequest,
) -> Result[MultipartForm, MultipartError] {
  parse_multipart_request(request.content_type, request.body)
}

///|
pub fn parse_and_validate_request(
  content_type : String,
  body : String,
  policy : ValidationPolicy,
) -> Result[ParseAndValidateResult, MultipartError] {
  match parse_multipart_request(content_type, body) {
    Ok(form) => Ok({ form, report: form.validate(policy) })
    Err(err) => Err(err)
  }
}

///|
pub fn validate_upload_request(
  request : MultipartRequest,
  policy : ValidationPolicy,
) -> Result[ValidationReport, MultipartError] {
  match parse_and_validate_request(request.content_type, request.body, policy) {
    Ok(result) => Ok(result.report)
    Err(err) => Err(err)
  }
}

///|
pub fn require_single_file(
  form : MultipartForm,
  name : String,
) -> Result[FormPart, MultipartError] {
  let files = form.files(name)
  if files.length() == 0 {
    Err(MalformedBody("required file is missing: " + name))
  } else if files.length() > 1 {
    Err(MalformedBody("expected a single file for field: " + name))
  } else {
    Ok(files[0])
  }
}

///|
pub fn require_single_field(
  form : MultipartForm,
  name : String,
) -> Result[String, MultipartError] {
  let values = form.field_values(name)
  if values.length() == 0 {
    Err(MalformedBody("required field is missing: " + name))
  } else if values.length() > 1 {
    Err(MalformedBody("expected a single value for field: " + name))
  } else {
    Ok(values[0])
  }
}

///|
pub fn collect_file_names(form : MultipartForm) -> Array[String] {
  let names = Array::new()
  let files = form.file_parts()
  let mut i = 0
  while i < files.length() {
    match files[i].filename {
      Some(filename) => names.push(filename)
      None => ()
    }
    i = i + 1
  }
  names
}

///|
pub fn collect_text_pairs(form : MultipartForm) -> Array[(String, String)] {
  let pairs = Array::new()
  let fields = form.text_parts()
  let mut i = 0
  while i < fields.length() {
    pairs.push((fields[i].name, fields[i].body))
    i = i + 1
  }
  pairs
}

///|
pub fn form_debug_report(form : MultipartForm) -> Array[String] {
  let lines = Array::new()
  lines.push("MoonFormData report")
  lines.push("boundary=" + form.boundary)
  let summary = form.summary()
  lines.push(summary.to_line())
  let debug_lines = form.debug_lines()
  let mut i = 0
  while i < debug_lines.length() {
    lines.push(debug_lines[i])
    i = i + 1
  }
  lines
}

///|
pub fn request_debug_report(
  request : MultipartRequest,
) -> Result[Array[String], MultipartError] {
  match roundtrip_request(request) {
    Ok(form) => Ok(form_debug_report(form))
    Err(err) => Err(err)
  }
}

///|
pub fn webhook_summary(
  content_type : String,
  body : String,
) -> Result[String, MultipartError] {
  match parse_multipart_request(content_type, body) {
    Ok(form) => Ok(form.summary().to_line())
    Err(err) => Err(err)
  }
}

///|
pub fn bad_request_message(err : MultipartError) -> String {
  "multipart/form-data request is invalid: " + err.message()
}

///|
pub fn ok_request_message(form : MultipartForm) -> String {
  "multipart/form-data request accepted: " + form.summary().to_line()
}

///|
pub fn accept_upload_request(
  request : MultipartRequest,
  policy : ValidationPolicy,
) -> Result[String, MultipartError] {
  match validate_upload_request(request, policy) {
    Ok(report) =>
      if report.is_ok() {
        match roundtrip_request(request) {
          Ok(form) => Ok(ok_request_message(form))
          Err(err) => Err(err)
        }
      } else {
        Err(MalformedBody(report.summary()))
      }
    Err(err) => Err(err)
  }
}

///|
pub fn request_content_length(request : MultipartRequest) -> Int {
  request.body.length()
}

///|
pub fn request_boundary(
  request : MultipartRequest,
) -> Result[String, MultipartError] {
  boundary_from_content_type(request.content_type)
}

///|
pub fn request_has_multipart_content_type(request : MultipartRequest) -> Bool {
  is_multipart_form_data_content_type(request.content_type)
}

///|
pub fn request_with_body(
  request : MultipartRequest,
  body : String,
) -> MultipartRequest {
  { content_type: request.content_type, body }
}

///|
pub fn request_with_content_type(
  request : MultipartRequest,
  content_type : String,
) -> MultipartRequest {
  { content_type, body: request.body }
}

///|
pub fn fixture_to_request(fixture : MultipartFixture) -> MultipartRequest {
  {
    content_type: "multipart/form-data; boundary=" + fixture.boundary,
    body: fixture.body,
  }
}
