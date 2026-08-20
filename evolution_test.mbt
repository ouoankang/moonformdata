///|
fn evolution_contract() -> @moonformdata.UploadContract {
  let schema = @moonformdata.strict_form_schema()
    .add_field_rule(
      @moonformdata.field_rule("title").with_max_values(2).with_max_length(100),
    )
    .add_file_rule(
      @moonformdata.file_rule("upload")
      .with_max_files(2)
      .with_max_length(1024)
      .allow_content_type("text/plain")
      .allow_content_type("image/png")
      .allow_extension("txt")
      .allow_extension("png"),
    )
  @moonformdata.upload_contract(schema).with_max_risk(@moonformdata.MediumRisk)
}

///|
test "contract diff reports unchanged contracts" {
  let contract = evolution_contract()
  let diff = @moonformdata.compare_upload_contracts(contract, contract)
  debug_inspect(diff.is_unchanged(), content="true")
  debug_inspect(diff.has_breaking_changes(), content="false")
  debug_inspect(
    diff.summary(),
    content="\"contract-diff: breaking=0, review=0, compatible=0\"",
  )
}

///|
test "contract diff detects a newly required field" {
  let previous = evolution_contract()
  let current = previous.with_schema(
    previous.schema.add_field_rule(
      @moonformdata.required_field_rule("title")
      .with_max_values(2)
      .with_max_length(100),
    ),
  )
  let diff = @moonformdata.compare_upload_contracts(previous, current)
  debug_inspect(diff.has_breaking_changes(), content="true")
  debug_inspect(diff.breaking_count(), content="1")
  debug_inspect(diff.changes[0].code, content="\"required_added\"")
}

///|
test "contract diff classifies relaxed limits as compatible" {
  let previous = evolution_contract()
  let options : @moonformdata.ParseOptions = {
    max_parts: previous.parse_options.max_parts + 10,
    max_headers_per_part: previous.parse_options.max_headers_per_part,
    max_body_length: previous.parse_options.max_body_length * 2,
  }
  let current = previous.with_parse_options(options)
  let diff = @moonformdata.compare_upload_contracts(previous, current)
  debug_inspect(diff.has_breaking_changes(), content="false")
  debug_inspect(diff.compatible_count(), content="2")
}

///|
test "contract diff detects a tighter parser limit" {
  let previous = evolution_contract()
  let options : @moonformdata.ParseOptions = {
    max_parts: 1,
    max_headers_per_part: previous.parse_options.max_headers_per_part,
    max_body_length: previous.parse_options.max_body_length,
  }
  let diff = @moonformdata.compare_upload_contracts(
    previous,
    previous.with_parse_options(options),
  )
  debug_inspect(diff.breaking_count(), content="1")
  debug_inspect(diff.changes[0].path, content="\"parse.max_parts\"")
}

///|
test "contract diff detects a narrower file allowlist" {
  let previous = evolution_contract()
  let current_schema = @moonformdata.strict_form_schema()
    .add_field_rule(
      @moonformdata.field_rule("title").with_max_values(2).with_max_length(100),
    )
    .add_file_rule(
      @moonformdata.file_rule("upload")
      .with_max_files(2)
      .with_max_length(1024)
      .allow_content_type("text/plain")
      .allow_extension("txt"),
    )
  let diff = @moonformdata.compare_upload_contracts(
    previous,
    previous.with_schema(current_schema),
  )
  debug_inspect(diff.breaking_count(), content="2")
  debug_inspect(diff.changes[0].code, content="\"allowlist_value_removed\"")
}

///|
test "contract diff detects closed unknown fields" {
  let previous = @moonformdata.upload_contract(
    @moonformdata.default_form_schema(),
  )
  let current = previous.with_schema(@moonformdata.strict_form_schema())
  let diff = @moonformdata.compare_upload_contracts(previous, current)
  debug_inspect(diff.breaking_count(), content="2")
  debug_inspect(diff.changes[0].code, content="\"unknown_entries_rejected\"")
}

///|
test "contract diff detects stricter risk ceilings" {
  let previous = evolution_contract().with_max_risk(@moonformdata.HighRisk)
  let current = previous.with_max_risk(@moonformdata.LowRisk)
  let diff = @moonformdata.compare_upload_contracts(previous, current)
  debug_inspect(diff.breaking_count(), content="1")
  debug_inspect(diff.changes[0].code, content="\"risk_ceiling_tightened\"")
}

///|
test "contract diff renders deterministic markdown" {
  let previous = evolution_contract()
  let current = previous.with_max_risk(@moonformdata.LowRisk)
  let markdown = @moonformdata.compare_upload_contracts(previous, current).to_markdown()
  debug_inspect(
    markdown.has_prefix("# Upload contract compatibility report\n"),
    content="true",
  )
  debug_inspect(
    markdown.find("risk_ceiling_tightened") is Some(_),
    content="true",
  )
}
