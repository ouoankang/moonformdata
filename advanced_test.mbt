///|
test "builder creates parseable multipart request" {
  let builder = @moonformdata.new_form_builder()
    .add_field("title", "MoonFormData")
    .add_file("upload", "../demo.txt", "hello", content_type="text/plain")
  match builder.with_boundary("builder") {
    Ok(with_boundary) =>
      match with_boundary.build_and_parse() {
        Ok(form) => {
          debug_inspect(form.part_count(), content="2")
          debug_inspect(
            form.field_value("title"),
            content="Some(\"MoonFormData\")",
          )
          debug_inspect(
            form.files("upload")[0].filename,
            content="Some(\"demo.txt\")",
          )
        }
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}

///|
test "builder rejects invalid boundary early" {
  let builder = @moonformdata.new_form_builder().add_field("a", "b")
  debug_inspect(
    builder.with_boundary("bad\r\nboundary"),
    content="Err(InvalidBoundary(\"bad\\r\\nboundary\"))",
  )
}

///|
test "part constructor and custom header helpers" {
  let part = @moonformdata.text_part("token", "abc")
  match @moonformdata.part_add_header(part, "X-Trace-Id", "one\r\ntwo") {
    Ok(with_header) => {
      debug_inspect(
        with_header.header("x-trace-id"),
        content="Some(\"onetwo\")",
      )
      debug_inspect(with_header.has_header("X-Trace-Id"), content="true")
      let removed = @moonformdata.part_remove_header(with_header, "x-trace-id")
      debug_inspect(removed.has_header("X-Trace-Id"), content="false")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "part encoded header block omits protected duplicate headers" {
  let part = @moonformdata.file_part(
    "avatar",
    "me.png",
    "data",
    content_type="image/png",
  )
  match @moonformdata.part_add_header(part, "Content-Disposition", "ignored") {
    Ok(with_header) =>
      match with_header.encoded_header_block() {
        Ok(block) =>
          debug_inspect(
            block,
            content="\"Content-Disposition: form-data; name=\\\"avatar\\\"; filename=\\\"me.png\\\"\\r\\nContent-Type: image/png\"",
          )
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}

///|
test "form query helpers summarize fields and files" {
  let parts = [
    @moonformdata.text_part("title", "A"),
    @moonformdata.text_part("tag", "x"),
    @moonformdata.text_part("tag", "y"),
    @moonformdata.file_part("file", "a.txt", "abc", content_type="text/plain"),
    @moonformdata.empty_file_part(
      "file",
      "empty.txt",
      content_type="text/plain",
    ),
  ]
  match @moonformdata.encode_multipart(parts, boundary="query") {
    Ok(encoded) =>
      match @moonformdata.parse_multipart(encoded.body, encoded.boundary) {
        Ok(form) => {
          let summary = form.summary()
          debug_inspect(summary.part_count, content="5")
          debug_inspect(summary.field_count, content="3")
          debug_inspect(summary.file_count, content="2")
          debug_inspect(summary.empty_file_count, content="1")
          debug_inspect(form.has_duplicate_field("tag"), content="true")
          debug_inspect(form.require_field("title"), content="Ok(\"A\")")
          debug_inspect(form.require_file("file") is Ok(_), content="true")
        }
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}

///|
test "content type and header formatting helpers" {
  match
    @moonformdata.MediaType::parse(
      "Multipart/Form-Data; Boundary=\"abc\"; Charset=utf-8",
    ) {
    Ok(media) => {
      debug_inspect(
        @moonformdata.format_media_type(media),
        content="\"multipart/form-data; boundary=abc; charset=utf-8\"",
      )
      debug_inspect(
        @moonformdata.is_multipart_form_data_content_type(
          "multipart/form-data; boundary=abc",
        ),
        content="true",
      )
      debug_inspect(
        @moonformdata.media_type_without_params("text/plain; charset=utf-8"),
        content="Ok(\"text/plain\")",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "content disposition filename star fallback" {
  match
    @moonformdata.ContentDisposition::parse(
      "form-data; name=\"file\"; filename=\"fallback.txt\"; filename*=UTF-8''better%20name.txt",
    ) {
    Ok(disposition) => {
      debug_inspect(
        @moonformdata.filename_from_disposition(disposition),
        content="Some(\"better name.txt\")",
      )
      debug_inspect(
        @moonformdata.encode_rfc5987_value("a b.txt"),
        content="\"UTF-8''a%20b.txt\"",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "filename policy removes risky input" {
  let policy = @moonformdata.strict_filename_policy()
  debug_inspect(
    @moonformdata.sanitize_filename_with_policy("C:\\tmp\\my script.sh", policy),
    content="\"my_script.sh.upload\"",
  )
  debug_inspect(
    @moonformdata.filename_extension("photo.JPG"),
    content="Some(\"jpg\")",
  )
  debug_inspect(
    @moonformdata.filename_has_extension("photo.JPG", ".jpg"),
    content="true",
  )
  debug_inspect(
    @moonformdata.filename_contains_path_separator("../x.txt"),
    content="true",
  )
  debug_inspect(
    @moonformdata.filename_looks_like_windows_drive("C:\\x.txt"),
    content="true",
  )
}

///|
test "image filename policy requires image extension" {
  let policy = @moonformdata.image_filename_policy()
  debug_inspect(
    @moonformdata.sanitize_filename_with_policy("avatar.png", policy),
    content="\"avatar.png\"",
  )
  debug_inspect(
    @moonformdata.sanitize_filename_with_policy("avatar", policy),
    content="\"avatar.bin\"",
  )
}

///|
test "validation policy catches missing and duplicate fields" {
  let parts = [
    @moonformdata.text_part("title", "A"),
    @moonformdata.text_part("title", "B"),
  ]
  match @moonformdata.encode_multipart(parts, boundary="validate") {
    Ok(encoded) =>
      match @moonformdata.parse_multipart(encoded.body, encoded.boundary) {
        Ok(form) => {
          let policy = @moonformdata.validation_policy_require_file(
            @moonformdata.strict_validation_policy(),
            "upload",
          )
          let report = form.validate(policy)
          debug_inspect(report.is_ok(), content="false")
          debug_inspect(report.issue_count(), content="2")
          debug_inspect(report.summary(), content="\"invalid: 2 issue(s)\"")
        }
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}

///|
test "validation policy accepts required upload" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="accept",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let policy = @moonformdata.validation_policy_allow_file_type(
    @moonformdata.validation_policy_require_file(
      @moonformdata.validation_policy_require_field(
        @moonformdata.default_validation_policy(),
        "title",
      ),
      "upload",
    ),
    "text/plain",
  )
  match @moonformdata.accept_upload_request(request, policy) {
    Ok(message) =>
      debug_inspect(message.find("accepted") is Some(_), content="true")
    Err(err) => fail(err.message())
  }
}

///|
test "request recipe parses content type boundary" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("a", "1"), ("b", "2")],
      boundary="recipe",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  debug_inspect(
    @moonformdata.request_boundary(request),
    content="Ok(\"recipe\")",
  )
  debug_inspect(
    @moonformdata.request_has_multipart_content_type(request),
    content="true",
  )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      debug_inspect(form.field_value("a"), content="Some(\"1\")")
      debug_inspect(form.field_value("b"), content="Some(\"2\")")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "request debug report exposes useful lines" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.binary_file_spec("payload", "data.bin", "0101")],
      boundary="debug",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.request_debug_report(request) {
    Ok(lines) => {
      debug_inspect(lines.length() >= 4, content="true")
      debug_inspect(lines[0], content="\"MoonFormData report\"")
      debug_inspect(lines[1], content="\"boundary=debug\"")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "fixtures parse and match declared shapes" {
  let fixtures = @moonformdata.standard_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    match @moonformdata.assert_fixture_shape(fixtures[i]) {
      Ok(summary) =>
        debug_inspect(
          summary.part_count,
          content=fixtures[i].expected_parts.to_string(),
        )
      Err(err) => fail(err.message())
    }
    i = i + 1
  }
}

///|
test "fixture to request can be parsed through request API" {
  let fixture = @moonformdata.fixture_mixed_upload()
  let request = @moonformdata.fixture_to_request(fixture)
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      debug_inspect(form.part_count(), content="3")
      debug_inspect(
        @moonformdata.collect_file_names(form),
        content="[\"a.txt\", \"b.txt\"]",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "require single helpers reject ambiguous fields" {
  let request = match
    @moonformdata.build_upload_request(
      [("tag", "a"), ("tag", "b")],
      [
        @moonformdata.text_file_spec("file", "a.txt", "A"),
        @moonformdata.text_file_spec("file", "b.txt", "B"),
      ],
      boundary="single",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      debug_inspect(
        @moonformdata.require_single_field(form, "tag") is Err(_),
        content="true",
      )
      debug_inspect(
        @moonformdata.require_single_file(form, "file") is Err(_),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}
