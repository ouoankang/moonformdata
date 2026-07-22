///|
pub(all) struct FormSummary {
  part_count : Int
  field_count : Int
  file_count : Int
  empty_file_count : Int
  total_body_length : Int
  distinct_name_count : Int
} derive(Debug, Eq)

///|
pub fn MultipartForm::part_count(self : MultipartForm) -> Int {
  self.parts.length()
}

///|
pub fn MultipartForm::is_empty(self : MultipartForm) -> Bool {
  self.parts.length() == 0
}

///|
pub fn MultipartForm::field_count(self : MultipartForm) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.parts.length() {
    if self.parts[i].is_text_field() {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
pub fn MultipartForm::file_count(self : MultipartForm) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.parts.length() {
    if self.parts[i].is_file() {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
pub fn MultipartForm::empty_file_count(self : MultipartForm) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.is_file() && part.body.length() == 0 {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
pub fn MultipartForm::total_body_length(self : MultipartForm) -> Int {
  let mut total = 0
  let mut i = 0
  while i < self.parts.length() {
    total = total + self.parts[i].body.length()
    i = i + 1
  }
  total
}

///|
pub fn MultipartForm::names(self : MultipartForm) -> Array[String] {
  let names = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let name = self.parts[i].name
    if !string_array_contains(names, name) {
      names.push(name)
    }
    i = i + 1
  }
  names
}

///|
pub fn MultipartForm::field_names(self : MultipartForm) -> Array[String] {
  let names = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.is_text_field() && !string_array_contains(names, part.name) {
      names.push(part.name)
    }
    i = i + 1
  }
  names
}

///|
pub fn MultipartForm::file_field_names(self : MultipartForm) -> Array[String] {
  let names = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.is_file() && !string_array_contains(names, part.name) {
      names.push(part.name)
    }
    i = i + 1
  }
  names
}

///|
pub fn MultipartForm::has_field(self : MultipartForm, name : String) -> Bool {
  self.field_value(name) is Some(_)
}

///|
pub fn MultipartForm::has_file(self : MultipartForm, name : String) -> Bool {
  self.files(name).length() > 0
}

///|
pub fn MultipartForm::parts_named(
  self : MultipartForm,
  name : String,
) -> Array[FormPart] {
  let out = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.name == name {
      out.push(part)
    }
    i = i + 1
  }
  out
}

///|
pub fn MultipartForm::first_part(
  self : MultipartForm,
  name : String,
) -> FormPart? {
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.name == name {
      return Some(part)
    }
    i = i + 1
  }
  None
}

///|
pub fn MultipartForm::text_parts(self : MultipartForm) -> Array[FormPart] {
  let out = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.is_text_field() {
      out.push(part)
    }
    i = i + 1
  }
  out
}

///|
pub fn MultipartForm::file_parts(self : MultipartForm) -> Array[FormPart] {
  let out = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.is_file() {
      out.push(part)
    }
    i = i + 1
  }
  out
}

///|
pub fn MultipartForm::require_field(
  self : MultipartForm,
  name : String,
) -> Result[String, MultipartError] {
  match self.field_value(name) {
    Some(value) => Ok(value)
    None => Err(MalformedBody("required form field is missing: " + name))
  }
}

///|
pub fn MultipartForm::require_file(
  self : MultipartForm,
  name : String,
) -> Result[FormPart, MultipartError] {
  let files = self.files(name)
  if files.length() == 0 {
    Err(MalformedBody("required file field is missing: " + name))
  } else {
    Ok(files[0])
  }
}

///|
pub fn MultipartForm::field_value_or(
  self : MultipartForm,
  name : String,
  fallback : String,
) -> String {
  self.field_value(name).unwrap_or(fallback)
}

///|
pub fn MultipartForm::has_duplicate_field(
  self : MultipartForm,
  name : String,
) -> Bool {
  self.field_values(name).length() > 1
}

///|
pub fn MultipartForm::has_duplicate_file_field(
  self : MultipartForm,
  name : String,
) -> Bool {
  self.files(name).length() > 1
}

///|
pub fn MultipartForm::summary(self : MultipartForm) -> FormSummary {
  {
    part_count: self.part_count(),
    field_count: self.field_count(),
    file_count: self.file_count(),
    empty_file_count: self.empty_file_count(),
    total_body_length: self.total_body_length(),
    distinct_name_count: self.names().length(),
  }
}

///|
pub fn FormSummary::to_line(self : FormSummary) -> String {
  "parts=" +
  self.part_count.to_string() +
  ", fields=" +
  self.field_count.to_string() +
  ", files=" +
  self.file_count.to_string() +
  ", empty_files=" +
  self.empty_file_count.to_string() +
  ", body_bytes=" +
  self.total_body_length.to_string() +
  ", names=" +
  self.distinct_name_count.to_string()
}

///|
pub fn MultipartForm::debug_lines(self : MultipartForm) -> Array[String] {
  let lines = Array::new()
  lines.push(self.summary().to_line())
  let mut i = 0
  while i < self.parts.length() {
    lines.push("#" + i.to_string() + " " + self.parts[i].debug_line())
    i = i + 1
  }
  lines
}

///|
fn string_array_contains(values : Array[String], target : String) -> Bool {
  let mut i = 0
  while i < values.length() {
    if values[i] == target {
      return true
    }
    i = i + 1
  }
  false
}
