///|
pub fn text_part(name : String, value : String) -> FormPart {
  { name, filename: None, content_type: None, headers: [], body: value }
}

///|
pub fn file_part(
  name : String,
  filename : String,
  body : String,
  content_type? : String,
) -> FormPart {
  {
    name,
    filename: Some(safe_filename(filename)),
    content_type,
    headers: [],
    body,
  }
}

///|
pub fn empty_file_part(
  name : String,
  filename : String,
  content_type? : String,
) -> FormPart {
  match content_type {
    Some(value) => file_part(name, filename, "", content_type=value)
    None => file_part(name, filename, "")
  }
}

///|
pub fn part_with_content_type(
  part : FormPart,
  content_type : String,
) -> FormPart {
  {
    name: part.name,
    filename: part.filename,
    content_type: Some(content_type),
    headers: clone_header_array(part.headers),
    body: part.body,
  }
}

///|
pub fn part_without_content_type(part : FormPart) -> FormPart {
  {
    name: part.name,
    filename: part.filename,
    content_type: None,
    headers: clone_header_array(part.headers),
    body: part.body,
  }
}

///|
pub fn part_with_body(part : FormPart, body : String) -> FormPart {
  {
    name: part.name,
    filename: part.filename,
    content_type: part.content_type,
    headers: clone_header_array(part.headers),
    body,
  }
}

///|
pub fn part_with_name(part : FormPart, name : String) -> FormPart {
  {
    name,
    filename: part.filename,
    content_type: part.content_type,
    headers: clone_header_array(part.headers),
    body: part.body,
  }
}

///|
pub fn part_with_filename(part : FormPart, filename : String) -> FormPart {
  {
    name: part.name,
    filename: Some(safe_filename(filename)),
    content_type: part.content_type,
    headers: clone_header_array(part.headers),
    body: part.body,
  }
}

///|
pub fn part_without_filename(part : FormPart) -> FormPart {
  {
    name: part.name,
    filename: None,
    content_type: part.content_type,
    headers: clone_header_array(part.headers),
    body: part.body,
  }
}

///|
pub fn part_add_header(
  part : FormPart,
  name : String,
  value : String,
) -> Result[FormPart, MultipartError] {
  if !is_safe_header_name(name) {
    return Err(InvalidHeader(name))
  }
  let headers = clone_header_array(part.headers)
  headers.push((name, strip_header_linebreaks(value)))
  Ok({
    name: part.name,
    filename: part.filename,
    content_type: part.content_type,
    headers,
    body: part.body,
  })
}

///|
pub fn part_replace_header(
  part : FormPart,
  name : String,
  value : String,
) -> Result[FormPart, MultipartError] {
  if !is_safe_header_name(name) {
    return Err(InvalidHeader(name))
  }
  let headers = Array::new()
  let mut replaced = false
  let mut i = 0
  while i < part.headers.length() {
    let (header_name, header_value) = part.headers[i]
    if header_name.compare_ignore_ascii_case(name) == 0 {
      headers.push((header_name, strip_header_linebreaks(value)))
      replaced = true
    } else {
      headers.push((header_name, header_value))
    }
    i = i + 1
  }
  if !replaced {
    headers.push((name, strip_header_linebreaks(value)))
  }
  Ok({
    name: part.name,
    filename: part.filename,
    content_type: part.content_type,
    headers,
    body: part.body,
  })
}

///|
pub fn part_remove_header(part : FormPart, name : String) -> FormPart {
  let headers = Array::new()
  let mut i = 0
  while i < part.headers.length() {
    let (header_name, value) = part.headers[i]
    if header_name.compare_ignore_ascii_case(name) != 0 {
      headers.push((header_name, value))
    }
    i = i + 1
  }
  {
    name: part.name,
    filename: part.filename,
    content_type: part.content_type,
    headers,
    body: part.body,
  }
}

///|
pub fn FormPart::is_file(self : FormPart) -> Bool {
  self.filename is Some(_)
}

///|
pub fn FormPart::is_text_field(self : FormPart) -> Bool {
  self.filename is None
}

///|
pub fn FormPart::body_length(self : FormPart) -> Int {
  self.body.length()
}

///|
pub fn FormPart::is_empty(self : FormPart) -> Bool {
  self.body.length() == 0
}

///|
pub fn FormPart::header(self : FormPart, name : String) -> String? {
  header_value(self.headers, name)
}

///|
pub fn FormPart::has_header(self : FormPart, name : String) -> Bool {
  self.header(name) is Some(_)
}

///|
pub fn FormPart::content_type_or(self : FormPart, fallback : String) -> String {
  self.content_type.unwrap_or(fallback)
}

///|
pub fn FormPart::filename_or(self : FormPart, fallback : String) -> String {
  self.filename.unwrap_or(fallback)
}

///|
pub fn FormPart::safe_filename(self : FormPart) -> String? {
  match self.filename {
    Some(value) => Some(safe_filename(value))
    None => None
  }
}

///|
pub fn FormPart::disposition_header(self : FormPart) -> String {
  let filename_segment = match self.filename {
    Some(filename) =>
      "; filename=\"" + escape_quoted(safe_filename(filename)) + "\""
    None => ""
  }
  "form-data; name=\"" + escape_quoted(self.name) + "\"" + filename_segment
}

///|
pub fn FormPart::encoded_header_block(
  self : FormPart,
) -> Result[String, MultipartError] {
  if self.name == "" {
    return Err(InvalidContentDisposition("part name must not be empty"))
  }
  let lines = Array::new()
  lines.push("Content-Disposition: " + self.disposition_header())
  match self.content_type {
    Some(content_type) =>
      if content_type != "" {
        lines.push("Content-Type: " + content_type)
      }
    None => ()
  }
  let mut i = 0
  while i < self.headers.length() {
    let (name, value) = self.headers[i]
    if !is_safe_header_name(name) {
      return Err(InvalidHeader(name))
    }
    if name.compare_ignore_ascii_case("Content-Disposition") != 0 &&
      name.compare_ignore_ascii_case("Content-Type") != 0 {
      lines.push(name + ": " + strip_header_linebreaks(value))
    }
    i = i + 1
  }
  Ok(lines.join("\r\n"))
}

///|
pub fn FormPart::debug_line(self : FormPart) -> String {
  let kind = if self.is_file() { "file" } else { "field" }
  let filename = match self.filename {
    Some(value) => "; filename=" + value
    None => ""
  }
  kind +
  "; name=" +
  self.name +
  filename +
  "; bytes=" +
  self.body.length().to_string()
}

///|
pub(all) struct FormBuilder {
  boundary : String?
  parts : Array[FormPart]
} derive(Debug, Eq)

///|
pub fn FormBuilder::new() -> FormBuilder {
  { boundary: None, parts: Array::new() }
}

///|
pub fn new_form_builder() -> FormBuilder {
  FormBuilder::new()
}

///|
pub fn FormBuilder::with_boundary(
  self : FormBuilder,
  boundary : String,
) -> Result[FormBuilder, MultipartError] {
  match validate_boundary(boundary) {
    Ok(value) =>
      Ok({ boundary: Some(value), parts: clone_part_array(self.parts) })
    Err(err) => Err(err)
  }
}

///|
pub fn FormBuilder::add_part(
  self : FormBuilder,
  part : FormPart,
) -> FormBuilder {
  self.parts.push(part)
  self
}

///|
pub fn FormBuilder::add_field(
  self : FormBuilder,
  name : String,
  value : String,
) -> FormBuilder {
  self.parts.push(text_part(name, value))
  self
}

///|
pub fn FormBuilder::add_file(
  self : FormBuilder,
  name : String,
  filename : String,
  body : String,
  content_type? : String,
) -> FormBuilder {
  match content_type {
    Some(value) =>
      self.parts.push(file_part(name, filename, body, content_type=value))
    None => self.parts.push(file_part(name, filename, body))
  }
  self
}

///|
pub fn FormBuilder::add_empty_file(
  self : FormBuilder,
  name : String,
  filename : String,
  content_type? : String,
) -> FormBuilder {
  match content_type {
    Some(value) =>
      self.parts.push(empty_file_part(name, filename, content_type=value))
    None => self.parts.push(empty_file_part(name, filename))
  }
  self
}

///|
pub fn FormBuilder::part_count(self : FormBuilder) -> Int {
  self.parts.length()
}

///|
pub fn FormBuilder::is_empty(self : FormBuilder) -> Bool {
  self.parts.length() == 0
}

///|
pub fn FormBuilder::to_parts(self : FormBuilder) -> Array[FormPart] {
  clone_part_array(self.parts)
}

///|
pub fn FormBuilder::build(
  self : FormBuilder,
) -> Result[EncodedForm, MultipartError] {
  match self.boundary {
    Some(boundary) => encode_multipart(self.parts, boundary~)
    None => encode_multipart(self.parts)
  }
}

///|
pub fn FormBuilder::build_and_parse(
  self : FormBuilder,
) -> Result[MultipartForm, MultipartError] {
  match self.build() {
    Ok(encoded) => parse_multipart(encoded.body, encoded.boundary)
    Err(err) => Err(err)
  }
}

///|
fn clone_part_array(parts : Array[FormPart]) -> Array[FormPart] {
  let out = Array::new()
  let mut i = 0
  while i < parts.length() {
    out.push(parts[i])
    i = i + 1
  }
  out
}

///|
fn clone_header_array(
  headers : Array[(String, String)],
) -> Array[(String, String)] {
  let out = Array::new()
  let mut i = 0
  while i < headers.length() {
    out.push(headers[i])
    i = i + 1
  }
  out
}
