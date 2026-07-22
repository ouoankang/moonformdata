///|
pub(all) struct MultipartFixture {
  name : String
  boundary : String
  body : String
  expected_parts : Int
  expected_fields : Int
  expected_files : Int
} derive(Debug, Eq)

///|
pub fn fixture_simple_fields() -> MultipartFixture {
  {
    name: "simple fields",
    boundary: "simple",
    body: "--simple\r\n" +
    "Content-Disposition: form-data; name=\"title\"\r\n" +
    "\r\n" +
    "MoonBit\r\n" +
    "--simple\r\n" +
    "Content-Disposition: form-data; name=\"tag\"\r\n" +
    "\r\n" +
    "parser\r\n" +
    "--simple--\r\n",
    expected_parts: 2,
    expected_fields: 2,
    expected_files: 0,
  }
}

///|
pub fn fixture_file_upload() -> MultipartFixture {
  {
    name: "file upload",
    boundary: "upload",
    body: "--upload\r\n" +
    "Content-Disposition: form-data; name=\"file\"; filename=\"report.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "hello\r\n" +
    "--upload--\r\n",
    expected_parts: 1,
    expected_fields: 0,
    expected_files: 1,
  }
}

///|
pub fn fixture_mixed_upload() -> MultipartFixture {
  {
    name: "mixed upload",
    boundary: "mixed",
    body: "--mixed\r\n" +
    "Content-Disposition: form-data; name=\"title\"\r\n" +
    "\r\n" +
    "demo\r\n" +
    "--mixed\r\n" +
    "Content-Disposition: form-data; name=\"file\"; filename=\"a.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "A\r\n" +
    "--mixed\r\n" +
    "Content-Disposition: form-data; name=\"file\"; filename=\"b.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "B\r\n" +
    "--mixed--\r\n",
    expected_parts: 3,
    expected_fields: 1,
    expected_files: 2,
  }
}

///|
pub fn fixture_empty_file() -> MultipartFixture {
  {
    name: "empty file",
    boundary: "empty",
    body: "--empty\r\n" +
    "Content-Disposition: form-data; name=\"file\"; filename=\"empty.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "\r\n" +
    "--empty--\r\n",
    expected_parts: 1,
    expected_fields: 0,
    expected_files: 1,
  }
}

///|
pub fn fixture_custom_headers() -> MultipartFixture {
  {
    name: "custom headers",
    boundary: "headers",
    body: "--headers\r\n" +
    "Content-Disposition: form-data; name=\"token\"\r\n" +
    "X-Trace-Id: abc123\r\n" +
    "\r\n" +
    "value\r\n" +
    "--headers--\r\n",
    expected_parts: 1,
    expected_fields: 1,
    expected_files: 0,
  }
}

///|
pub fn fixture_quoted_boundary() -> (String, String) {
  (
    "multipart/form-data; charset=utf-8; boundary=\"quoted-boundary\"", "quoted-boundary",
  )
}

///|
pub fn standard_fixtures() -> Array[MultipartFixture] {
  [
    fixture_simple_fields(),
    fixture_file_upload(),
    fixture_mixed_upload(),
    fixture_empty_file(),
    fixture_custom_headers(),
  ]
}

///|
pub fn parse_fixture(
  fixture : MultipartFixture,
) -> Result[MultipartForm, MultipartError] {
  parse_multipart(fixture.body, fixture.boundary)
}

///|
pub fn fixture_status_line(fixture : MultipartFixture) -> String {
  fixture.name +
  ": parts=" +
  fixture.expected_parts.to_string() +
  ", fields=" +
  fixture.expected_fields.to_string() +
  ", files=" +
  fixture.expected_files.to_string()
}

///|
pub fn assert_fixture_shape(
  fixture : MultipartFixture,
) -> Result[FormSummary, MultipartError] {
  match parse_fixture(fixture) {
    Ok(form) => {
      let summary = form.summary()
      if summary.part_count != fixture.expected_parts {
        return Err(
          MalformedBody("fixture part count mismatch: " + fixture.name),
        )
      }
      if summary.field_count != fixture.expected_fields {
        return Err(
          MalformedBody("fixture field count mismatch: " + fixture.name),
        )
      }
      if summary.file_count != fixture.expected_files {
        return Err(
          MalformedBody("fixture file count mismatch: " + fixture.name),
        )
      }
      Ok(summary)
    }
    Err(err) => Err(err)
  }
}
