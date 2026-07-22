///|
test "analysis summarizes ordinary upload request" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.text_file_spec("upload", "note.txt", "hello")],
      boundary="analysis",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.analyze_request(request) {
    Ok(analysis) => {
      debug_inspect(analysis.summary.part_count, content="2")
      debug_inspect(analysis.fields.length(), content="1")
      debug_inspect(analysis.files.length(), content="1")
      debug_inspect(analysis.risk, content="LowRisk")
      debug_inspect(
        analysis.compact_line().find("risk=low") is Some(_),
        content="true",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "analysis records duplicate and empty text field notes" {
  let request = match
    @moonformdata.build_request_from_fields(
      [("tag", "a"), ("tag", ""), ("title", "demo")],
      boundary="notes",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.analyze_request(request) {
    Ok(analysis) => {
      debug_inspect(analysis.risk, content="MediumRisk")
      debug_inspect(analysis.has_note("duplicate text field"), content="true")
      debug_inspect(analysis.has_note("empty text field"), content="true")
      debug_inspect(analysis.fields[0].duplicated, content="true")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "analysis flags executable uploads" {
  let request = match
    @moonformdata.build_upload_request(
      [],
      [@moonformdata.file_spec("script", "run.sh", "text/plain", "echo hi")],
      boundary="risk",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.analyze_request(request) {
    Ok(analysis) => {
      debug_inspect(analysis.risk, content="HighRisk")
      debug_inspect(analysis.files[0].risk, content="HighRisk")
      debug_inspect(analysis.has_note("high risk file"), content="true")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "analysis counts content types and names" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [
        @moonformdata.file_spec("upload", "a.txt", "text/plain", "A"),
        @moonformdata.file_spec("upload", "b.txt", "text/plain", "B"),
      ],
      boundary="counts",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      let name_counts = @moonformdata.form_name_counts(form)
      let type_counts = @moonformdata.form_content_type_counts(form)
      debug_inspect(
        @moonformdata.find_name_count(name_counts, "upload"),
        content="2",
      )
      debug_inspect(
        @moonformdata.find_name_count(type_counts, "text/plain"),
        content="2",
      )
    }
    Err(err) => fail(err.message())
  }
}

///|
test "analysis lines are stable for CLI reporting" {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "demo")],
      [@moonformdata.binary_file_spec("payload", "data.bin", "01")],
      boundary="lines",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  match @moonformdata.request_analysis_lines(request) {
    Ok(lines) => {
      debug_inspect(lines[0], content="\"MoonFormData analysis\"")
      debug_inspect(lines[1].find("risk=medium") is Some(_), content="true")
      debug_inspect(lines.length() >= 6, content="true")
    }
    Err(err) => fail(err.message())
  }
}

///|
test "body size classes cover thresholds" {
  debug_inspect(@moonformdata.body_size_class(0), content="EmptyBody")
  debug_inspect(@moonformdata.body_size_class(10), content="TinyBody")
  debug_inspect(@moonformdata.body_size_class(2048), content="SmallBody")
  debug_inspect(@moonformdata.body_size_class(1024 * 128), content="MediumBody")
  debug_inspect(
    @moonformdata.body_size_class(1024 * 1024 * 2),
    content="LargeBody",
  )
}

///|
test "analysis detects active boundary marker in constructed body" {
  let form = @moonformdata.MultipartForm::{
    boundary: "manual",
    parts: [
      @moonformdata.FormPart::{
        name: "text",
        filename: None,
        content_type: None,
        headers: [],
        body: "body mentions --manual inside",
      },
    ],
  }
  let analysis = @moonformdata.analyze_form(form)
  debug_inspect(
    @moonformdata.detect_boundary_in_part_bodies(form),
    content="true",
  )
  debug_inspect(analysis.risk, content="HighRisk")
  debug_inspect(analysis.has_note("active boundary"), content="true")
}

///|
test "analysis includes header profiles" {
  let part = match
    @moonformdata.part_add_header(
      @moonformdata.text_part("title", "demo"),
      "X-Trace-Id",
      "abc",
    ) {
    Ok(value) => value
    Err(err) => fail(err.message())
  }
  let form = @moonformdata.MultipartForm::{ boundary: "headers", parts: [part] }
  let analysis = @moonformdata.analyze_form(form)
  debug_inspect(analysis.headers.length(), content="1")
  debug_inspect(
    analysis.headers[0].to_line(),
    content="\"X-Trace-Id: count=1, first=abc\"",
  )
}
