///|
pub(all) struct ValidationPolicy {
  required_fields : Array[String]
  required_files : Array[String]
  allowed_file_content_types : Array[String]
  max_text_length : Int
  max_file_length : Int
  max_filename_length : Int
  allow_empty_files : Bool
  allow_duplicate_fields : Bool
  allow_duplicate_files : Bool
} derive(Debug, Eq)

///|
pub(all) struct ValidationIssue {
  code : String
  message : String
  part_index : Int?
  field_name : String?
} derive(Debug, Eq)

///|
pub(all) struct ValidationReport {
  issues : Array[ValidationIssue]
} derive(Debug, Eq)

///|
pub fn default_validation_policy() -> ValidationPolicy {
  {
    required_fields: [],
    required_files: [],
    allowed_file_content_types: [],
    max_text_length: 1024 * 256,
    max_file_length: 1024 * 1024 * 4,
    max_filename_length: 120,
    allow_empty_files: true,
    allow_duplicate_fields: true,
    allow_duplicate_files: true,
  }
}

///|
pub fn strict_validation_policy() -> ValidationPolicy {
  {
    required_fields: [],
    required_files: [],
    allowed_file_content_types: [],
    max_text_length: 1024 * 64,
    max_file_length: 1024 * 1024,
    max_filename_length: 80,
    allow_empty_files: false,
    allow_duplicate_fields: false,
    allow_duplicate_files: true,
  }
}

///|
pub fn validate_form(
  form : MultipartForm,
  policy : ValidationPolicy,
) -> ValidationReport {
  let issues = Array::new()
  validate_required_fields(form, policy, issues)
  validate_required_files(form, policy, issues)
  validate_parts(form, policy, issues)
  validate_duplicates(form, policy, issues)
  { issues, }
}

///|
pub fn MultipartForm::validate(
  self : MultipartForm,
  policy : ValidationPolicy,
) -> ValidationReport {
  validate_form(self, policy)
}

///|
pub fn ValidationReport::is_ok(self : ValidationReport) -> Bool {
  self.issues.length() == 0
}

///|
pub fn ValidationReport::issue_count(self : ValidationReport) -> Int {
  self.issues.length()
}

///|
pub fn ValidationReport::first_message(self : ValidationReport) -> String? {
  if self.issues.length() == 0 {
    None
  } else {
    Some(self.issues[0].message)
  }
}

///|
pub fn ValidationReport::messages(self : ValidationReport) -> Array[String] {
  let messages = Array::new()
  let mut i = 0
  while i < self.issues.length() {
    messages.push(self.issues[i].message)
    i = i + 1
  }
  messages
}

///|
pub fn ValidationReport::summary(self : ValidationReport) -> String {
  if self.is_ok() {
    "ok"
  } else {
    "invalid: " + self.issues.length().to_string() + " issue(s)"
  }
}

///|
pub fn ValidationIssue::to_line(self : ValidationIssue) -> String {
  let index = match self.part_index {
    Some(value) => "part=" + value.to_string()
    None => "part=-"
  }
  let field = match self.field_name {
    Some(value) => "field=" + value
    None => "field=-"
  }
  self.code + "; " + index + "; " + field + "; " + self.message
}

///|
pub fn validation_issue(
  code : String,
  message : String,
  part_index? : Int,
  field_name? : String,
) -> ValidationIssue {
  { code, message, part_index, field_name }
}

///|
pub fn validation_policy_require_field(
  policy : ValidationPolicy,
  name : String,
) -> ValidationPolicy {
  let required_fields = clone_string_array(policy.required_fields)
  required_fields.push(name)
  {
    required_fields,
    required_files: clone_string_array(policy.required_files),
    allowed_file_content_types: clone_string_array(
      policy.allowed_file_content_types,
    ),
    max_text_length: policy.max_text_length,
    max_file_length: policy.max_file_length,
    max_filename_length: policy.max_filename_length,
    allow_empty_files: policy.allow_empty_files,
    allow_duplicate_fields: policy.allow_duplicate_fields,
    allow_duplicate_files: policy.allow_duplicate_files,
  }
}

///|
pub fn validation_policy_require_file(
  policy : ValidationPolicy,
  name : String,
) -> ValidationPolicy {
  let required_files = clone_string_array(policy.required_files)
  required_files.push(name)
  {
    required_fields: clone_string_array(policy.required_fields),
    required_files,
    allowed_file_content_types: clone_string_array(
      policy.allowed_file_content_types,
    ),
    max_text_length: policy.max_text_length,
    max_file_length: policy.max_file_length,
    max_filename_length: policy.max_filename_length,
    allow_empty_files: policy.allow_empty_files,
    allow_duplicate_fields: policy.allow_duplicate_fields,
    allow_duplicate_files: policy.allow_duplicate_files,
  }
}

///|
pub fn validation_policy_allow_file_type(
  policy : ValidationPolicy,
  content_type : String,
) -> ValidationPolicy {
  let allowed = clone_string_array(policy.allowed_file_content_types)
  allowed.push(to_lower_ascii(content_type))
  {
    required_fields: clone_string_array(policy.required_fields),
    required_files: clone_string_array(policy.required_files),
    allowed_file_content_types: allowed,
    max_text_length: policy.max_text_length,
    max_file_length: policy.max_file_length,
    max_filename_length: policy.max_filename_length,
    allow_empty_files: policy.allow_empty_files,
    allow_duplicate_fields: policy.allow_duplicate_fields,
    allow_duplicate_files: policy.allow_duplicate_files,
  }
}

///|
fn validate_required_fields(
  form : MultipartForm,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < policy.required_fields.length() {
    let name = policy.required_fields[i]
    if !form.has_field(name) {
      issues.push(
        validation_issue(
          "missing_field",
          "required field is missing: " + name,
          field_name=name,
        ),
      )
    }
    i = i + 1
  }
}

///|
fn validate_required_files(
  form : MultipartForm,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < policy.required_files.length() {
    let name = policy.required_files[i]
    if !form.has_file(name) {
      issues.push(
        validation_issue(
          "missing_file",
          "required file is missing: " + name,
          field_name=name,
        ),
      )
    }
    i = i + 1
  }
}

///|
fn validate_parts(
  form : MultipartForm,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  let mut i = 0
  while i < form.parts.length() {
    let part = form.parts[i]
    if part.name == "" {
      issues.push(
        validation_issue(
          "empty_name",
          "part name must not be empty",
          part_index=i,
        ),
      )
    }
    if part.is_file() {
      validate_file_part(part, i, policy, issues)
    } else {
      validate_text_part(part, i, policy, issues)
    }
    i = i + 1
  }
}

///|
fn validate_text_part(
  part : FormPart,
  index : Int,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  if policy.max_text_length >= 0 && part.body.length() > policy.max_text_length {
    issues.push(
      validation_issue(
        "text_too_large",
        "text field exceeds max_text_length: " + part.name,
        part_index=index,
        field_name=part.name,
      ),
    )
  }
}

///|
fn validate_file_part(
  part : FormPart,
  index : Int,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  if !policy.allow_empty_files && part.body.length() == 0 {
    issues.push(
      validation_issue(
        "empty_file",
        "empty file is not allowed: " + part.name,
        part_index=index,
        field_name=part.name,
      ),
    )
  }
  if policy.max_file_length >= 0 && part.body.length() > policy.max_file_length {
    issues.push(
      validation_issue(
        "file_too_large",
        "file exceeds max_file_length: " + part.name,
        part_index=index,
        field_name=part.name,
      ),
    )
  }
  match part.filename {
    Some(filename) =>
      if policy.max_filename_length >= 0 &&
        filename.length() > policy.max_filename_length {
        issues.push(
          validation_issue(
            "filename_too_long",
            "filename exceeds max_filename_length: " + filename,
            part_index=index,
            field_name=part.name,
          ),
        )
      }
    None =>
      issues.push(
        validation_issue(
          "missing_filename",
          "file part has no filename: " + part.name,
          part_index=index,
          field_name=part.name,
        ),
      )
  }
  if policy.allowed_file_content_types.length() > 0 {
    match part.content_type {
      Some(content_type) =>
        if !content_type_allowed(
            content_type,
            policy.allowed_file_content_types,
          ) {
          issues.push(
            validation_issue(
              "content_type_not_allowed",
              "file content type is not allowed: " + content_type,
              part_index=index,
              field_name=part.name,
            ),
          )
        }
      None =>
        issues.push(
          validation_issue(
            "missing_content_type",
            "file content type is required: " + part.name,
            part_index=index,
            field_name=part.name,
          ),
        )
    }
  }
}

///|
fn validate_duplicates(
  form : MultipartForm,
  policy : ValidationPolicy,
  issues : Array[ValidationIssue],
) -> Unit {
  let names = form.names()
  let mut i = 0
  while i < names.length() {
    let name = names[i]
    if !policy.allow_duplicate_fields && form.field_values(name).length() > 1 {
      issues.push(
        validation_issue(
          "duplicate_field",
          "duplicate text field is not allowed: " + name,
          field_name=name,
        ),
      )
    }
    if !policy.allow_duplicate_files && form.files(name).length() > 1 {
      issues.push(
        validation_issue(
          "duplicate_file",
          "duplicate file field is not allowed: " + name,
          field_name=name,
        ),
      )
    }
    i = i + 1
  }
}

///|
fn content_type_allowed(content_type : String, allowed : Array[String]) -> Bool {
  let lower = to_lower_ascii(content_type)
  let mut i = 0
  while i < allowed.length() {
    if lower == to_lower_ascii(allowed[i]) {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn clone_string_array(values : Array[String]) -> Array[String] {
  let out = Array::new()
  let mut i = 0
  while i < values.length() {
    out.push(values[i])
    i = i + 1
  }
  out
}
