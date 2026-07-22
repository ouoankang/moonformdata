///|
test "extract boundary from content type" {
  let result = @moonformdata.boundary_from_content_type(
    "multipart/form-data; boundary=\"demo-123\"",
  )
  debug_inspect(result, content="Ok(\"demo-123\")")
}

///|
test "parse ordinary fields and repeated fields" {
  let body = "--abc\r\n" +
    "Content-Disposition: form-data; name=\"title\"\r\n" +
    "\r\n" +
    "MoonBit\r\n" +
    "--abc\r\n" +
    "Content-Disposition: form-data; name=\"tag\"\r\n" +
    "\r\n" +
    "compiler\r\n" +
    "--abc\r\n" +
    "Content-Disposition: form-data; name=\"tag\"\r\n" +
    "\r\n" +
    "ecosystem\r\n" +
    "--abc--\r\n"
  match @moonformdata.parse_multipart(body, "abc") {
    Ok(form) => {
      debug_inspect(form.parts.length(), content="3")
      debug_inspect(form.field_value("title"), content="Some(\"MoonBit\")")
      debug_inspect(
        form.field_values("tag"),
        content="[\"compiler\", \"ecosystem\"]",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "parse file upload and sanitize filename" {
  let body = "--upload\r\n" +
    "Content-Disposition: form-data; name=\"avatar\"; filename=\"..\\\\evil.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "hello file\r\n" +
    "--upload--\r\n"
  match @moonformdata.parse_multipart(body, "upload") {
    Ok(form) => {
      let files = form.files("avatar")
      debug_inspect(files.length(), content="1")
      debug_inspect(files[0].filename, content="Some(\"evil.txt\")")
      debug_inspect(files[0].content_type, content="Some(\"text/plain\")")
      debug_inspect(files[0].body, content="\"hello file\"")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "parse empty file upload" {
  let body = "--upload\r\n" +
    "Content-Disposition: form-data; name=\"attachment\"; filename=\"empty.txt\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    "\r\n" +
    "--upload--\r\n"
  match @moonformdata.parse_multipart(body, "upload") {
    Ok(form) => {
      let files = form.files("attachment")
      debug_inspect(files.length(), content="1")
      debug_inspect(files[0].filename, content="Some(\"empty.txt\")")
      debug_inspect(files[0].body, content="\"\"")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "encode then parse multipart" {
  let parts = [
    @moonformdata.FormPart::{
      name: "message",
      filename: None,
      content_type: None,
      headers: [],
      body: "hello",
    },
    @moonformdata.FormPart::{
      name: "file",
      filename: Some("note.txt"),
      content_type: Some("text/plain"),
      headers: [],
      body: "content",
    },
  ]
  match @moonformdata.encode_multipart(parts, boundary="roundtrip") {
    Ok(encoded) =>
      match @moonformdata.parse_multipart(encoded.body, encoded.boundary) {
        Ok(form) => {
          debug_inspect(
            encoded.content_type,
            content="\"multipart/form-data; boundary=roundtrip\"",
          )
          debug_inspect(form.field_value("message"), content="Some(\"hello\")")
          debug_inspect(form.files("file")[0].body, content="\"content\"")
        }
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}

///|
test "report missing and invalid boundaries" {
  debug_inspect(
    @moonformdata.boundary_from_content_type("multipart/form-data"),
    content="Err(MissingBoundary)",
  )
  debug_inspect(
    @moonformdata.parse_multipart("--abc--\r\n", "bad\r\nboundary"),
    content="Err(InvalidBoundary(\"bad\\r\\nboundary\"))",
  )
}

///|
test "reject malformed headers and missing closing boundary" {
  let bad_header = "--abc\r\n" +
    "Content-Disposition form-data; name=\"x\"\r\n" +
    "\r\n" +
    "value\r\n" +
    "--abc--\r\n"
  debug_inspect(
    @moonformdata.parse_multipart(bad_header, "abc"),
    content="Err(InvalidHeader(\"Content-Disposition form-data; name=\\\"x\\\"\"))",
  )
  let missing_close = "--abc\r\n" +
    "Content-Disposition: form-data; name=\"x\"\r\n" +
    "\r\n" +
    "value\r\n"
  debug_inspect(
    @moonformdata.parse_multipart(missing_close, "abc"),
    content="Err(MalformedBody(\"closing boundary not found\"))",
  )
}
