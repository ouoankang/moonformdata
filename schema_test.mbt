///|
test "schema accepts required fields and upload" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="schema-ok",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.default_form_schema()
    .add_field_rule(@moonformdata.required_field_rule("title"))
    .add_file_rule(
      @moonformdata.required_file_rule("upload")
      .allow_content_type("text/plain")
      .allow_extension(".txt"),
    )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) =>
      debug_inspect(form.validate_schema(schema).is_ok(), content="true")
    Err(err) => fail(err.message())
  }
}

///|
test "schema reports missing required entries" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("title", "demo")],
      boundary="schema-missing",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.form_schema_require_file(
    @moonformdata.form_schema_require_field(
      @moonformdata.default_form_schema(),
      "token",
    ),
    "upload",
  )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let report = form.validate_schema(schema)
      debug_inspect(
        report.has_issue_code("schema_missing_field"),
        content="true",
      )
      debug_inspect(
        report.has_issue_code("schema_missing_file"),
        content="true",
      )
      debug_inspect(report.issue_count(), content="2")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema limits repeated field values" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("tag", "a"), ("tag", "b")],
      boundary="schema-repeat",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.default_form_schema().add_field_rule(
    @moonformdata.field_rule("tag").with_max_values(1),
  )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let report = form.validate_schema(schema)
      debug_inspect(
        report.has_issue_code("schema_too_many_field_values"),
        content="true",
      )
      debug_inspect(report.issues_for_field("tag").length(), content="1")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema checks empty and oversized text fields" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("title", ""), ("body", "abcdef")],
      boundary="schema-text",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.default_form_schema()
    .add_field_rule(@moonformdata.field_rule("title").with_allow_empty(false))
    .add_field_rule(@moonformdata.field_rule("body").with_max_length(3))
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let report = form.validate_schema(schema)
      debug_inspect(report.has_issue_code("schema_empty_field"), content="true")
      debug_inspect(
        report.has_issue_code("schema_field_too_large"),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema checks file type extension and length" {
  let request = match
    @moonformdata.build_upload_request(
      [],
      [
        @moonformdata.file_spec(
          "upload", "payload.bin", "application/octet-stream", "abcdef",
        ),
      ],
      boundary="schema-file",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let rule = @moonformdata.required_file_rule("upload")
    .with_max_length(3)
    .allow_content_type("text/plain")
    .allow_extension("txt")
  let schema = @moonformdata.default_form_schema().add_file_rule(rule)
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let report = form.validate_schema(schema)
      debug_inspect(
        report.has_issue_code("schema_file_too_large"),
        content="true",
      )
      debug_inspect(
        report.has_issue_code("schema_content_type_not_allowed"),
        content="true",
      )
      debug_inspect(
        report.has_issue_code("schema_extension_not_allowed"),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema can reject unknown fields and files" {
  let request = match
    @moonformdata.build_upload_request(
      [("known", "yes"), ("extra", "no")],
      [@moonformdata.text_file_spec("unknown_file", "a.txt", "A")],
      boundary="schema-unknown",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.strict_form_schema().add_field_rule(
    @moonformdata.field_rule("known"),
  )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let report = form.validate_schema(schema)
      debug_inspect(
        report.has_issue_code("schema_unknown_field"),
        content="true",
      )
      debug_inspect(
        report.has_issue_code("schema_unknown_file"),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema parse and validate request helper returns form and report" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="schema-helper",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.default_form_schema()
    .add_field_rule(@moonformdata.required_field_rule("title"))
    .add_file_rule(@moonformdata.required_file_rule("upload"))
  match
    @moonformdata.parse_and_validate_schema_request(
      request.content_type,
      request.body,
      schema,
    ) {
    Ok(result) => {
      debug_inspect(result.form.part_count(), content="2")
      debug_inspect(result.report.is_ok(), content="true")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "schema report renders issue lines" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("title", "")],
      boundary="schema-lines",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let schema = @moonformdata.default_form_schema().add_field_rule(
    @moonformdata.field_rule("title").with_allow_empty(false),
  )
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let lines = form.validate_schema(schema).to_lines()
      debug_inspect(lines.length(), content="1")
      debug_inspect(
        lines[0].find("schema_empty_field") is Some(_),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}
