///|
fn main {
  let request = match
    @moonformdata.build_upload_request(
      [("title", "MoonFormData"), ("tag", "moonbit")],
      [@moonformdata.text_file_spec("upload", "../hello.txt", "hello")],
      boundary="example",
    ) {
    Ok(value) => value
    Err(err) => {
      println("encode failed: " + err.message())
      return
    }
  }

  println(request.content_type)
  match @moonformdata.roundtrip_request(request) {
    Ok(form) => {
      println(form.summary().to_line())
      println("title=" + form.require_field("title").unwrap())
      println(
        "filename=" + form.require_file("upload").unwrap().filename_or("<none>"),
      )
      let schema = @moonformdata.default_form_schema()
        .add_field_rule(@moonformdata.required_field_rule("title"))
        .add_file_rule(
          @moonformdata.required_file_rule("upload")
          .allow_content_type("text/plain")
          .allow_extension("txt"),
        )
      println("schema=" + form.validate_schema(schema).summary())
      println("analysis=" + @moonformdata.analyze_form(form).compact_line())
    }
    Err(err) => println("parse failed: " + err.message())
  }
}
