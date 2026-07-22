///|
test "regression corpus exposes many declared fixtures" {
  debug_inspect(@moonformdata.regression_fixture_count(), content="84")
  let names = @moonformdata.regression_fixture_names()
  debug_inspect(names.length(), content="84")
  debug_inspect(names[0], content="\"case 001 api upload\"")
  debug_inspect(names[83], content="\"case 084 final acceptance upload\"")
}

///|
test "regression corpus parses all fixture bodies" {
  let fixtures = @moonformdata.regression_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    match @moonformdata.parse_fixture(fixtures[i]) {
      Ok(form) => {
        debug_inspect(form.part_count(), content="3")
        debug_inspect(form.field_count(), content="2")
        debug_inspect(form.file_count(), content="1")
        debug_inspect(form.has_field("title"), content="true")
        debug_inspect(form.has_field("tag"), content="true")
        debug_inspect(form.has_file("upload"), content="true")
      }
      Err(err) => fail(fixtures[i].name + ": " + err.message())
    }
    i = i + 1
  }
}

///|
test "regression corpus fixture shapes match declarations" {
  let fixtures = @moonformdata.regression_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    match @moonformdata.assert_fixture_shape(fixtures[i]) {
      Ok(summary) => {
        debug_inspect(
          summary.part_count,
          content=fixtures[i].expected_parts.to_string(),
        )
        debug_inspect(
          summary.field_count,
          content=fixtures[i].expected_fields.to_string(),
        )
        debug_inspect(
          summary.file_count,
          content=fixtures[i].expected_files.to_string(),
        )
      }
      Err(err) => fail(fixtures[i].name + ": " + err.message())
    }
    i = i + 1
  }
}

///|
test "regression corpus supports request wrapper API" {
  let fixtures = @moonformdata.regression_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    let request = @moonformdata.fixture_to_request(fixtures[i])
    debug_inspect(
      @moonformdata.request_has_multipart_content_type(request),
      content="true",
    )
    match @moonformdata.roundtrip_request(request) {
      Ok(form) => {
        debug_inspect(form.summary().part_count, content="3")
        debug_inspect(
          @moonformdata.collect_file_names(form).length(),
          content="1",
        )
      }
      Err(err) => fail(fixtures[i].name + ": " + err.message())
    }
    i = i + 1
  }
}

///|
test "regression corpus validates with default policy" {
  let fixtures = @moonformdata.regression_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    match @moonformdata.parse_fixture(fixtures[i]) {
      Ok(form) => {
        let report = form.validate(@moonformdata.default_validation_policy())
        debug_inspect(report.is_ok(), content="true")
      }
      Err(err) => fail(fixtures[i].name + ": " + err.message())
    }
    i = i + 1
  }
}

///|
test "regression corpus detects strict empty file case" {
  let fixtures = @moonformdata.regression_fixtures()
  let empty = fixtures[5]
  match @moonformdata.parse_fixture(empty) {
    Ok(form) => {
      let report = form.validate(@moonformdata.strict_validation_policy())
      debug_inspect(report.is_ok(), content="false")
      debug_inspect(
        report.first_message(),
        content="Some(\"empty file is not allowed: upload\")",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "regression corpus can rebuild first fixture" {
  let fixtures = @moonformdata.regression_fixtures()
  let first = fixtures[0]
  match @moonformdata.parse_fixture(first) {
    Ok(form) =>
      match
        @moonformdata.encode_multipart(form.parts, boundary=first.boundary) {
        Ok(encoded) =>
          match @moonformdata.parse_multipart(encoded.body, encoded.boundary) {
            Ok(roundtrip) => {
              debug_inspect(
                roundtrip.summary().part_count,
                content=form.summary().part_count.to_string(),
              )
              debug_inspect(
                roundtrip.summary().field_count,
                content=form.summary().field_count.to_string(),
              )
              debug_inspect(
                roundtrip.summary().file_count,
                content=form.summary().file_count.to_string(),
              )
            }
            Err(err) => fail(err.message())
          }
        Err(err) => fail(err.message())
      }
    Err(err) => fail(err.message())
  }
}
