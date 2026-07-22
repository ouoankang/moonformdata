///|
test "parse request rejects non multipart content type" {
  debug_inspect(
    @moonformdata.parse_multipart_request("application/json", "{}"),
    content="Err(InvalidContentType(\"application/json\"))",
  )
}

///|
test "parse request rejects content type without boundary" {
  debug_inspect(
    @moonformdata.parse_multipart_request("multipart/form-data", ""),
    content="Err(MissingBoundary)",
  )
}

///|
test "parse options enforce body length" {
  let options = @moonformdata.ParseOptions::{
    max_parts: 4,
    max_headers_per_part: 4,
    max_body_length: 5,
  }
  debug_inspect(
    @moonformdata.parse_multipart_with_options("--abc--\r\n", "abc", options),
    content="Err(LimitExceeded(\"body length exceeds ParseOptions.max_body_length\"))",
  )
}

///|
test "parse options enforce part count" {
  let body = "--abc\r\n" +
    "Content-Disposition: form-data; name=\"a\"\r\n" +
    "\r\n" +
    "1\r\n" +
    "--abc\r\n" +
    "Content-Disposition: form-data; name=\"b\"\r\n" +
    "\r\n" +
    "2\r\n" +
    "--abc--\r\n"
  let options = @moonformdata.ParseOptions::{
    max_parts: 1,
    max_headers_per_part: 4,
    max_body_length: 1024,
  }
  debug_inspect(
    @moonformdata.parse_multipart_with_options(body, "abc", options),
    content="Err(LimitExceeded(\"part count exceeds ParseOptions.max_parts\"))",
  )
}

///|
test "parse options enforce header count" {
  let body = "--abc\r\n" +
    "Content-Disposition: form-data; name=\"a\"\r\n" +
    "X-One: 1\r\n" +
    "X-Two: 2\r\n" +
    "\r\n" +
    "1\r\n" +
    "--abc--\r\n"
  let options = @moonformdata.ParseOptions::{
    max_parts: 4,
    max_headers_per_part: 1,
    max_body_length: 1024,
  }
  debug_inspect(
    @moonformdata.parse_multipart_with_options(body, "abc", options),
    content="Err(LimitExceeded(\"header count exceeds ParseOptions.max_headers_per_part\"))",
  )
}

///|
test "parser accepts lf only bodies" {
  let body = "--abc\n" +
    "Content-Disposition: form-data; name=\"a\"\n" +
    "\n" +
    "1\n" +
    "--abc--\n"
  match @moonformdata.parse_multipart(body, "abc") {
    Ok(form) => debug_inspect(form.field_value("a"), content="Some(\"1\")")
    Err(err) => fail(err.message())
  }
}

///|
test "parser rejects unexpected preamble" {
  let body = "hello--abc\r\n" +
    "Content-Disposition: form-data; name=\"a\"\r\n" +
    "\r\n" +
    "1\r\n" +
    "--abc--\r\n"
  debug_inspect(
    @moonformdata.parse_multipart(body, "abc"),
    content="Err(MalformedBody(\"unexpected preamble before first boundary\"))",
  )
}

///|
test "parser rejects unexpected closing suffix" {
  debug_inspect(
    @moonformdata.parse_multipart("--abc--oops\r\n", "abc"),
    content="Err(MalformedBody(\"unexpected data after closing boundary\"))",
  )
}

///|
test "parser rejects part without separator" {
  debug_inspect(
    @moonformdata.parse_multipart(
      "--abc\r\nContent-Disposition: form-data; name=\"a\"\r\n--abc--\r\n", "abc",
    ),
    content="Err(MalformedBody(\"part has no header/body separator\"))",
  )
}

///|
test "header helper rejects invalid header name" {
  debug_inspect(
    @moonformdata.set_header([], "Bad Header", "value"),
    content="Err(InvalidHeader(\"Bad Header\"))",
  )
}

///|
test "header helper normalizes names" {
  debug_inspect(
    @moonformdata.normalize_header_name("content-type"),
    content="\"Content-Type\"",
  )
  debug_inspect(
    @moonformdata.normalize_header_name("x-trace-id"),
    content="\"X-Trace-Id\"",
  )
}

///|
test "percent decoder rejects malformed escapes" {
  debug_inspect(
    @moonformdata.decode_percent_ascii("a%2"),
    content="Err(InvalidContentDisposition(\"a%2\"))",
  )
  debug_inspect(
    @moonformdata.decode_percent_ascii("a%XZ"),
    content="Err(InvalidContentDisposition(\"a%XZ\"))",
  )
}

///|
test "filename star falls back to regular filename when malformed" {
  match
    @moonformdata.ContentDisposition::parse(
      "form-data; name=\"file\"; filename=\"fallback.txt\"; filename*=UTF-8''bad%XZ",
    ) {
    Ok(disposition) =>
      debug_inspect(
        @moonformdata.filename_from_disposition(disposition),
        content="Some(\"fallback.txt\")",
      )
    Err(err) => fail(err.message())
  }
}

///|
test "filename security notes explain normalization" {
  let notes = @moonformdata.filename_security_notes("C:\\tmp\\bad\rname.txt")
  debug_inspect(notes.length() >= 3, content="true")
  debug_inspect(notes[0], content="\"path separator removed\"")
}

///|
test "request mutation helpers preserve fields" {
  let request = match
    @moonformdata.build_request_from_fields([("a", "b")], boundary="mutate") {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let changed = @moonformdata.request_with_content_type(
    request, "multipart/form-data; boundary=mutate",
  )
  let same_body = @moonformdata.request_with_body(changed, request.body)
  match @moonformdata.roundtrip_request(same_body) {
    Ok(form) => debug_inspect(form.field_value("a"), content="Some(\"b\")")
    Err(err) => fail(err.message())
  }
}

///|
test "webhook summary reports parsed shape" {
  let request = match
    @moonformdata.build_upload_request(
      [("event", "push")],
      [@moonformdata.text_file_spec("payload", "payload.txt", "body")],
      boundary="webhook",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.webhook_summary(request.content_type, request.body) {
    Ok(summary) =>
      debug_inspect(
        summary,
        content="\"parts=2, fields=1, files=1, empty_files=0, body_bytes=8, names=2\"",
      )
    Err(err) => fail(err.message())
  }
}
