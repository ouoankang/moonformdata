///|
pub(all) struct FieldRule {
  name : String
  required : Bool
  max_values : Int
  max_length : Int
  allow_empty : Bool
} derive(Debug, Eq)

///|
pub(all) struct FileRule {
  name : String
  required : Bool
  max_files : Int
  max_length : Int
  allowed_content_types : Array[String]
  allowed_extensions : Array[String]
  allow_empty : Bool
} derive(Debug, Eq)

///|
pub(all) struct FormSchema {
  field_rules : Array[FieldRule]
  file_rules : Array[FileRule]
  allow_unknown_fields : Bool
  allow_unknown_files : Bool
} derive(Debug, Eq)

///|
pub fn field_rule(name : String) -> FieldRule {
  { name, required: false, max_values: -1, max_length: -1, allow_empty: true }
}

///|
pub fn required_field_rule(name : String) -> FieldRule {
  field_rule(name).with_required(true)
}

///|
pub fn file_rule(name : String) -> FileRule {
  {
    name,
    required: false,
    max_files: -1,
    max_length: -1,
    allowed_content_types: [],
    allowed_extensions: [],
    allow_empty: true,
  }
}

///|
pub fn required_file_rule(name : String) -> FileRule {
  file_rule(name).with_required(true)
}

///|
pub fn default_form_schema() -> FormSchema {
  {
    field_rules: [],
    file_rules: [],
    allow_unknown_fields: true,
    allow_unknown_files: true,
  }
}

///|
pub fn strict_form_schema() -> FormSchema {
  {
    field_rules: [],
    file_rules: [],
    allow_unknown_fields: false,
    allow_unknown_files: false,
  }
}

///|
pub fn FieldRule::with_required(self : FieldRule, required : Bool) -> FieldRule {
  {
    name: self.name,
    required,
    max_values: self.max_values,
    max_length: self.max_length,
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FieldRule::with_max_values(
  self : FieldRule,
  max_values : Int,
) -> FieldRule {
  {
    name: self.name,
    required: self.required,
    max_values,
    max_length: self.max_length,
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FieldRule::with_max_length(
  self : FieldRule,
  max_length : Int,
) -> FieldRule {
  {
    name: self.name,
    required: self.required,
    max_values: self.max_values,
    max_length,
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FieldRule::with_allow_empty(
  self : FieldRule,
  allow_empty : Bool,
) -> FieldRule {
  {
    name: self.name,
    required: self.required,
    max_values: self.max_values,
    max_length: self.max_length,
    allow_empty,
  }
}

///|
pub fn FileRule::with_required(self : FileRule, required : Bool) -> FileRule {
  {
    name: self.name,
    required,
    max_files: self.max_files,
    max_length: self.max_length,
    allowed_content_types: clone_string_array(self.allowed_content_types),
    allowed_extensions: clone_string_array(self.allowed_extensions),
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FileRule::with_max_files(self : FileRule, max_files : Int) -> FileRule {
  {
    name: self.name,
    required: self.required,
    max_files,
    max_length: self.max_length,
    allowed_content_types: clone_string_array(self.allowed_content_types),
    allowed_extensions: clone_string_array(self.allowed_extensions),
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FileRule::with_max_length(self : FileRule, max_length : Int) -> FileRule {
  {
    name: self.name,
    required: self.required,
    max_files: self.max_files,
    max_length,
    allowed_content_types: clone_string_array(self.allowed_content_types),
    allowed_extensions: clone_string_array(self.allowed_extensions),
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FileRule::with_allow_empty(
  self : FileRule,
  allow_empty : Bool,
) -> FileRule {
  {
    name: self.name,
    required: self.required,
    max_files: self.max_files,
    max_length: self.max_length,
    allowed_content_types: clone_string_array(self.allowed_content_types),
    allowed_extensions: clone_string_array(self.allowed_extensions),
    allow_empty,
  }
}

///|
pub fn FileRule::allow_content_type(
  self : FileRule,
  content_type : String,
) -> FileRule {
  let allowed = clone_string_array(self.allowed_content_types)
  allowed.push(to_lower_ascii(content_type))
  {
    name: self.name,
    required: self.required,
    max_files: self.max_files,
    max_length: self.max_length,
    allowed_content_types: allowed,
    allowed_extensions: clone_string_array(self.allowed_extensions),
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FileRule::allow_extension(
  self : FileRule,
  extension : String,
) -> FileRule {
  let allowed = clone_string_array(self.allowed_extensions)
  allowed.push(normalize_rule_extension(extension))
  {
    name: self.name,
    required: self.required,
    max_files: self.max_files,
    max_length: self.max_length,
    allowed_content_types: clone_string_array(self.allowed_content_types),
    allowed_extensions: allowed,
    allow_empty: self.allow_empty,
  }
}

///|
pub fn FormSchema::with_unknown_fields(
  self : FormSchema,
  allow : Bool,
) -> FormSchema {
  {
    field_rules: clone_field_rules(self.field_rules),
    file_rules: clone_file_rules(self.file_rules),
    allow_unknown_fields: allow,
    allow_unknown_files: self.allow_unknown_files,
  }
}

///|
pub fn FormSchema::with_unknown_files(
  self : FormSchema,
  allow : Bool,
) -> FormSchema {
  {
    field_rules: clone_field_rules(self.field_rules),
    file_rules: clone_file_rules(self.file_rules),
    allow_unknown_fields: self.allow_unknown_fields,
    allow_unknown_files: allow,
  }
}

///|
pub fn FormSchema::add_field_rule(
  self : FormSchema,
  rule : FieldRule,
) -> FormSchema {
  let field_rules = clone_field_rules(self.field_rules)
  upsert_field_rule(field_rules, rule)
  {
    field_rules,
    file_rules: clone_file_rules(self.file_rules),
    allow_unknown_fields: self.allow_unknown_fields,
    allow_unknown_files: self.allow_unknown_files,
  }
}

///|
pub fn FormSchema::add_file_rule(
  self : FormSchema,
  rule : FileRule,
) -> FormSchema {
  let file_rules = clone_file_rules(self.file_rules)
  upsert_file_rule(file_rules, rule)
  {
    field_rules: clone_field_rules(self.field_rules),
    file_rules,
    allow_unknown_fields: self.allow_unknown_fields,
    allow_unknown_files: self.allow_unknown_files,
  }
}

///|
pub fn form_schema_require_field(
  schema : FormSchema,
  name : String,
) -> FormSchema {
  schema.add_field_rule(required_field_rule(name))
}

///|
pub fn form_schema_require_file(
  schema : FormSchema,
  name : String,
) -> FormSchema {
  schema.add_file_rule(required_file_rule(name))
}

///|
pub fn validate_form_schema(
  form : MultipartForm,
  schema : FormSchema,
) -> ValidationReport {
  let issues = Array::new()
  validate_schema_field_rules(form, schema, issues)
  validate_schema_file_rules(form, schema, issues)
  validate_unknown_text_fields(form, schema, issues)
  validate_unknown_file_fields(form, schema, issues)
  { issues, }
}

///|
pub fn MultipartForm::validate_schema(
  self : MultipartForm,
  schema : FormSchema,
) -> ValidationReport {
  validate_form_schema(self, schema)
}

///|
pub fn parse_and_validate_schema_request(
  content_type : String,
  body : String,
  schema : FormSchema,
) -> Result[ParseAndValidateResult, MultipartError] {
  match parse_multipart_request(content_type, body) {
    Ok(form) => Ok({ form, report: form.validate_schema(schema) })
    Err(err) => Err(err)
  }
}

///|
pub fn ValidationReport::has_issue_code(
  self : ValidationReport,
  code : String,
) -> Bool {
  let mut i = 0
  while i < self.issues.length() {
    if self.issues[i].code == code {
      return true
    }
    i = i + 1
  }
  false
}

///|
pub fn ValidationReport::issues_for_field(
  self : ValidationReport,
  name : String,
) -> Array[ValidationIssue] {
  let out = Array::new()
  let mut i = 0
  while i < self.issues.length() {
    match self.issues[i].field_name {
      Some(field) => if field == name { out.push(self.issues[i]) }
      None => ()
    }
    i = i + 1
  }
  out
}

///|
pub fn ValidationReport::to_lines(self : ValidationReport) -> Array[String] {
  let lines = Array::new()
  if self.is_ok() {
    lines.push("ok")
  } else {
    let mut i = 0
    while i < self.issues.length() {
      lines.push(self.issues[i].to_line())
      i = i + 1
    }
  }
  lines
}

///|
fn validate_schema_field_rules(
  form : MultipartForm,
  schema : FormSchema,
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < schema.field_rules.length() {
    validate_one_field_rule(form, schema.field_rules[i], issues)
    i = i + 1
  }
}

///|
fn validate_one_field_rule(
  form : MultipartForm,
  rule : FieldRule,
  issues : Array[ValidationIssue],
) -> Unit {
  let values = form.field_values(rule.name)
  if rule.required && values.length() == 0 {
    issues.push(
      validation_issue(
        "schema_missing_field",
        "required field is missing: " + rule.name,
        field_name=rule.name,
      ),
    )
  }
  if rule.max_values >= 0 && values.length() > rule.max_values {
    issues.push(
      validation_issue(
        "schema_too_many_field_values",
        "field has too many values: " + rule.name,
        field_name=rule.name,
      ),
    )
  }
  let mut i = 0
  while i < values.length() {
    if !rule.allow_empty && values[i] == "" {
      issues.push(
        validation_issue(
          "schema_empty_field",
          "empty field is not allowed: " + rule.name,
          field_name=rule.name,
        ),
      )
    }
    if rule.max_length >= 0 && values[i].length() > rule.max_length {
      issues.push(
        validation_issue(
          "schema_field_too_large",
          "field exceeds max_length: " + rule.name,
          field_name=rule.name,
        ),
      )
    }
    i = i + 1
  }
}

///|
fn validate_schema_file_rules(
  form : MultipartForm,
  schema : FormSchema,
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < schema.file_rules.length() {
    validate_one_file_rule(form, schema.file_rules[i], issues)
    i = i + 1
  }
}

///|
fn validate_one_file_rule(
  form : MultipartForm,
  rule : FileRule,
  issues : Array[ValidationIssue],
) -> Unit {
  let files = form.files(rule.name)
  if rule.required && files.length() == 0 {
    issues.push(
      validation_issue(
        "schema_missing_file",
        "required file is missing: " + rule.name,
        field_name=rule.name,
      ),
    )
  }
  if rule.max_files >= 0 && files.length() > rule.max_files {
    issues.push(
      validation_issue(
        "schema_too_many_files",
        "file field has too many files: " + rule.name,
        field_name=rule.name,
      ),
    )
  }
  let mut i = 0
  while i < files.length() {
    validate_one_schema_file(files[i], i, rule, issues)
    i = i + 1
  }
}

///|
fn validate_one_schema_file(
  part : FormPart,
  index : Int,
  rule : FileRule,
  issues : Array[ValidationIssue],
) -> Unit {
  if !rule.allow_empty && part.body == "" {
    issues.push(
      validation_issue(
        "schema_empty_file",
        "empty file is not allowed: " + rule.name,
        part_index=index,
        field_name=rule.name,
      ),
    )
  }
  if rule.max_length >= 0 && part.body.length() > rule.max_length {
    issues.push(
      validation_issue(
        "schema_file_too_large",
        "file exceeds max_length: " + rule.name,
        part_index=index,
        field_name=rule.name,
      ),
    )
  }
  if rule.allowed_content_types.length() > 0 &&
    !schema_content_type_allowed(part.content_type, rule.allowed_content_types) {
    issues.push(
      validation_issue(
        "schema_content_type_not_allowed",
        "file content type is not allowed: " + rule.name,
        part_index=index,
        field_name=rule.name,
      ),
    )
  }
  if rule.allowed_extensions.length() > 0 &&
    !schema_extension_allowed(part.filename, rule.allowed_extensions) {
    issues.push(
      validation_issue(
        "schema_extension_not_allowed",
        "file extension is not allowed: " + rule.name,
        part_index=index,
        field_name=rule.name,
      ),
    )
  }
}

///|
fn validate_unknown_text_fields(
  form : MultipartForm,
  schema : FormSchema,
  issues : Array[ValidationIssue],
) -> Unit {
  if schema.allow_unknown_fields {
    return
  }
  let names = form.field_names()
  let mut i = 0
  while i < names.length() {
    if field_rule_for(schema, names[i]) is None {
      issues.push(
        validation_issue(
          "schema_unknown_field",
          "unknown field is not allowed: " + names[i],
          field_name=names[i],
        ),
      )
    }
    i = i + 1
  }
}

///|
fn validate_unknown_file_fields(
  form : MultipartForm,
  schema : FormSchema,
  issues : Array[ValidationIssue],
) -> Unit {
  if schema.allow_unknown_files {
    return
  }
  let names = form.file_field_names()
  let mut i = 0
  while i < names.length() {
    if file_rule_for(schema, names[i]) is None {
      issues.push(
        validation_issue(
          "schema_unknown_file",
          "unknown file is not allowed: " + names[i],
          field_name=names[i],
        ),
      )
    }
    i = i + 1
  }
}

///|
fn field_rule_for(schema : FormSchema, name : String) -> FieldRule? {
  let mut i = 0
  while i < schema.field_rules.length() {
    if schema.field_rules[i].name == name {
      return Some(schema.field_rules[i])
    }
    i = i + 1
  }
  None
}

///|
fn file_rule_for(schema : FormSchema, name : String) -> FileRule? {
  let mut i = 0
  while i < schema.file_rules.length() {
    if schema.file_rules[i].name == name {
      return Some(schema.file_rules[i])
    }
    i = i + 1
  }
  None
}

///|
fn schema_content_type_allowed(
  content_type : String?,
  allowed : Array[String],
) -> Bool {
  match content_type {
    Some(value) => string_array_contains_case_insensitive(allowed, value)
    None => false
  }
}

///|
fn schema_extension_allowed(
  filename : String?,
  allowed : Array[String],
) -> Bool {
  match filename {
    Some(value) =>
      match filename_extension(value) {
        Some(ext) => string_array_contains_case_insensitive(allowed, ext)
        None => false
      }
    None => false
  }
}

///|
fn string_array_contains_case_insensitive(
  values : Array[String],
  target : String,
) -> Bool {
  let lower = to_lower_ascii(target)
  let mut i = 0
  while i < values.length() {
    if to_lower_ascii(values[i]) == lower {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn normalize_rule_extension(extension : String) -> String {
  let trimmed = trim_ascii(extension)
  if trimmed.has_prefix(".") {
    to_lower_ascii(slice_from(trimmed, 1))
  } else {
    to_lower_ascii(trimmed)
  }
}

///|
fn upsert_field_rule(rules : Array[FieldRule], rule : FieldRule) -> Unit {
  let mut i = 0
  while i < rules.length() {
    if rules[i].name == rule.name {
      rules[i] = rule
      return
    }
    i = i + 1
  }
  rules.push(rule)
}

///|
fn upsert_file_rule(rules : Array[FileRule], rule : FileRule) -> Unit {
  let mut i = 0
  while i < rules.length() {
    if rules[i].name == rule.name {
      rules[i] = rule
      return
    }
    i = i + 1
  }
  rules.push(rule)
}

///|
fn clone_field_rules(rules : Array[FieldRule]) -> Array[FieldRule] {
  let out = Array::new()
  let mut i = 0
  while i < rules.length() {
    out.push(rules[i])
    i = i + 1
  }
  out
}

///|
fn clone_file_rules(rules : Array[FileRule]) -> Array[FileRule] {
  let out = Array::new()
  let mut i = 0
  while i < rules.length() {
    out.push(rules[i])
    i = i + 1
  }
  out
}
