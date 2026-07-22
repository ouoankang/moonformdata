///|
/// A parsed `Content-Type` or part-level media type value.
pub(all) struct MediaType {
  typ : String
  subtype : String
  params : Array[(String, String)]
} derive(Debug, Eq)

///|
/// Parsed `Content-Disposition` metadata for one multipart part.
pub(all) struct ContentDisposition {
  disposition : String
  params : Array[(String, String)]
} derive(Debug, Eq)

///|
/// A single multipart part. File uploads have a `filename`; ordinary form
/// fields do not.
pub(all) struct FormPart {
  name : String
  filename : String?
  content_type : String?
  headers : Array[(String, String)]
  body : String
} derive(Debug, Eq)

///|
/// Parsed form data. `parts` preserves wire order, including repeated fields.
pub(all) struct MultipartForm {
  boundary : String
  parts : Array[FormPart]
} derive(Debug, Eq)

///|
/// Parser limits for the in-memory v1 implementation.
pub(all) struct ParseOptions {
  max_parts : Int
  max_headers_per_part : Int
  max_body_length : Int
} derive(Debug, Eq)

///|
/// Result of `encode_multipart`.
pub(all) struct EncodedForm {
  content_type : String
  body : String
  boundary : String
} derive(Debug, Eq)

///|
/// Structured errors make validation failures explainable in examples and CI.
pub(all) enum MultipartError {
  MissingBoundary
  InvalidBoundary(String)
  InvalidHeader(String)
  InvalidContentType(String)
  InvalidContentDisposition(String)
  MalformedBody(String)
  LimitExceeded(String)
} derive(Debug, Eq)

///|
/// Human-readable error message for logs, CLI examples, and HTTP 400 replies.
pub fn MultipartError::message(self : MultipartError) -> String {
  match self {
    MissingBoundary => "missing multipart boundary"
    InvalidBoundary(value) =>
      "invalid multipart boundary: " + display_snippet(value)
    InvalidHeader(value) =>
      "invalid multipart header: " + display_snippet(value)
    InvalidContentType(value) =>
      "invalid Content-Type: " + display_snippet(value)
    InvalidContentDisposition(value) =>
      "invalid Content-Disposition: " + display_snippet(value)
    MalformedBody(value) =>
      "malformed multipart body: " + display_snippet(value)
    LimitExceeded(value) =>
      "multipart parser limit exceeded: " + display_snippet(value)
  }
}

///|
/// Conservative defaults for small and medium form payloads.
pub fn default_parse_options() -> ParseOptions {
  { max_parts: 128, max_headers_per_part: 32, max_body_length: 1024 * 1024 * 4 }
}

///|
/// Parse `Content-Type` and extract the `boundary` parameter.
pub fn boundary_from_content_type(
  header : String,
) -> Result[String, MultipartError] {
  match MediaType::parse(header) {
    Ok(media) =>
      if media.typ != "multipart" || media.subtype != "form-data" {
        Err(InvalidContentType(header))
      } else {
        match media.param("boundary") {
          Some(boundary) => validate_boundary(boundary)
          None => Err(MissingBoundary)
        }
      }
    Err(err) => Err(err)
  }
}

///|
/// Parse a media type such as `multipart/form-data; boundary=abc`.
pub fn MediaType::parse(header : String) -> Result[MediaType, MultipartError] {
  let pieces = split_header_parameters(header)
  if pieces.length() == 0 {
    return Err(InvalidContentType(header))
  }
  let main = trim_ascii(pieces[0])
  match main.split_once("/") {
    Some((typ_view, subtype_view)) => {
      let typ = to_lower_ascii(trim_ascii(typ_view.to_owned()))
      let subtype = to_lower_ascii(trim_ascii(subtype_view.to_owned()))
      if typ == "" || subtype == "" {
        return Err(InvalidContentType(header))
      }
      let params = Array::new()
      let mut i = 1
      while i < pieces.length() {
        match parse_parameter(pieces[i]) {
          Ok((name, value)) => params.push((to_lower_ascii(name), value))
          Err(_) => return Err(InvalidContentType(header))
        }
        i = i + 1
      }
      Ok({ typ, subtype, params })
    }
    None => Err(InvalidContentType(header))
  }
}

///|
/// Return a parameter by ASCII case-insensitive name.
pub fn MediaType::param(self : MediaType, name : String) -> String? {
  find_param(self.params, name)
}

///|
/// Parse a `Content-Disposition` header.
pub fn ContentDisposition::parse(
  header : String,
) -> Result[ContentDisposition, MultipartError] {
  let pieces = split_header_parameters(header)
  if pieces.length() == 0 {
    return Err(InvalidContentDisposition(header))
  }
  let disposition = to_lower_ascii(trim_ascii(pieces[0]))
  if disposition == "" {
    return Err(InvalidContentDisposition(header))
  }
  let params = Array::new()
  let mut i = 1
  while i < pieces.length() {
    match parse_parameter(pieces[i]) {
      Ok((name, value)) => params.push((to_lower_ascii(name), value))
      Err(_) => return Err(InvalidContentDisposition(header))
    }
    i = i + 1
  }
  Ok({ disposition, params })
}

///|
/// Return a disposition parameter by ASCII case-insensitive name.
pub fn ContentDisposition::param(
  self : ContentDisposition,
  name : String,
) -> String? {
  find_param(self.params, name)
}

///|
/// Parse an in-memory multipart body with conservative default limits.
pub fn parse_multipart(
  body : String,
  boundary : String,
) -> Result[MultipartForm, MultipartError] {
  parse_multipart_with_options(body, boundary, default_parse_options())
}

///|
/// Parse an in-memory multipart body with caller-provided limits.
pub fn parse_multipart_with_options(
  body : String,
  boundary : String,
  options : ParseOptions,
) -> Result[MultipartForm, MultipartError] {
  let checked_boundary = match validate_boundary(boundary) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  if body.length() > options.max_body_length {
    return Err(
      LimitExceeded("body length exceeds ParseOptions.max_body_length"),
    )
  }
  let delimiter = "--" + checked_boundary
  let first = body.find(delimiter)
  match first {
    None => Err(MalformedBody("opening boundary not found"))
    Some(start) => {
      if start != 0 &&
        slice_string(body, 0, start) != "\r\n" &&
        slice_string(body, 0, start) != "\n" {
        return Err(MalformedBody("unexpected preamble before first boundary"))
      }
      parse_sections(slice_from(body, start), checked_boundary, options)
    }
  }
}

///|
/// Build a multipart body. The returned `content_type` is ready for HTTP use.
pub fn encode_multipart(
  parts : Array[FormPart],
  boundary? : String,
) -> Result[EncodedForm, MultipartError] {
  let candidate = match boundary {
    Some(value) => value
    None => "MoonFormDataBoundary0000000000000001"
  }
  let checked_boundary = match validate_boundary(candidate) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  if parts.length() == 0 {
    return Err(MalformedBody("cannot encode an empty multipart form"))
  }
  let out = Array::new()
  let mut i = 0
  while i < parts.length() {
    let part = parts[i]
    if part.name == "" {
      return Err(InvalidContentDisposition("part name must not be empty"))
    }
    let filename_segment = match part.filename {
      Some(filename) =>
        "; filename=\"" + escape_quoted(safe_filename(filename)) + "\""
      None => ""
    }
    out.push("--" + checked_boundary + "\r\n")
    out.push(
      "Content-Disposition: form-data; name=\"" +
      escape_quoted(part.name) +
      "\"" +
      filename_segment +
      "\r\n",
    )
    match part.content_type {
      Some(content_type) =>
        if content_type != "" {
          out.push("Content-Type: " + content_type + "\r\n")
        }
      None => ()
    }
    let mut h = 0
    while h < part.headers.length() {
      let (name, value) = part.headers[h]
      if !is_safe_header_name(name) {
        return Err(InvalidHeader(name))
      }
      if name.compare_ignore_ascii_case("Content-Disposition") != 0 &&
        name.compare_ignore_ascii_case("Content-Type") != 0 {
        out.push(name + ": " + strip_header_linebreaks(value) + "\r\n")
      }
      h = h + 1
    }
    out.push("\r\n")
    out.push(part.body)
    out.push("\r\n")
    i = i + 1
  }
  out.push("--" + checked_boundary + "--\r\n")
  Ok({
    content_type: "multipart/form-data; boundary=" + checked_boundary,
    body: out.join(""),
    boundary: checked_boundary,
  })
}

///|
/// Return all values for an ordinary form field.
pub fn MultipartForm::field_values(
  self : MultipartForm,
  name : String,
) -> Array[String] {
  let values = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.name == name && part.filename is None {
      values.push(part.body)
    }
    i = i + 1
  }
  values
}

///|
/// Return the first ordinary form field value.
pub fn MultipartForm::field_value(
  self : MultipartForm,
  name : String,
) -> String? {
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.name == name && part.filename is None {
      return Some(part.body)
    }
    i = i + 1
  }
  None
}

///|
/// Return file parts for a given field name.
pub fn MultipartForm::files(
  self : MultipartForm,
  name : String,
) -> Array[FormPart] {
  let files = Array::new()
  let mut i = 0
  while i < self.parts.length() {
    let part = self.parts[i]
    if part.name == name && part.filename is Some(_) {
      files.push(part)
    }
    i = i + 1
  }
  files
}

///|
/// Remove path separators, drive prefixes, and control characters from a client
/// supplied filename. Returns `"upload.bin"` when no safe character remains.
pub fn safe_filename(filename : String) -> String {
  let normalized = filename.replace_all(old="\\", new="/")
  let mut base = normalized
  match normalized.rev_split_once("/") {
    Some((_, tail)) => base = tail.to_owned()
    None => ()
  }
  if base.length() >= 2 && base[1] == 58 {
    base = slice_from(base, 2)
  }
  let chars = Array::new()
  let mut i = 0
  while i < base.length() {
    let code = base[i]
    if code >= 32 && code != 47 && code != 92 && code != 58 {
      chars.push(char_at(base, i))
    }
    i = i + 1
  }
  let cleaned = trim_ascii(String::from_array(chars))
  if cleaned == "" || cleaned == "." || cleaned == ".." {
    "upload.bin"
  } else {
    cleaned
  }
}

///|
fn parse_sections(
  source : String,
  boundary : String,
  options : ParseOptions,
) -> Result[MultipartForm, MultipartError] {
  let marker = "--" + boundary
  let sections = source.split(marker).collect()
  let parts = Array::new()
  let mut closed = false
  let mut i = 1
  while i < sections.length() {
    let raw = sections[i].to_owned()
    if raw.has_prefix("--") {
      let tail = slice_from(raw, 2)
      if tail == "" || tail == "\r\n" || tail == "\n" {
        closed = true
        break
      }
      return Err(MalformedBody("unexpected data after closing boundary"))
    }
    if raw == "" {
      return Err(MalformedBody("empty boundary section"))
    }
    let section = strip_one_leading_newline(raw)
    if section != "" {
      let part = match parse_part(section, options) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      parts.push(part)
      if parts.length() > options.max_parts {
        return Err(LimitExceeded("part count exceeds ParseOptions.max_parts"))
      }
    }
    i = i + 1
  }
  if !closed {
    Err(MalformedBody("closing boundary not found"))
  } else {
    Ok({ boundary, parts })
  }
}

///|
fn parse_part(
  section : String,
  options : ParseOptions,
) -> Result[FormPart, MultipartError] {
  let split = match section.find("\r\n\r\n") {
    Some(idx) => Some((idx, 4))
    None =>
      match section.find("\n\n") {
        Some(idx) => Some((idx, 2))
        None => None
      }
  }
  match split {
    None => Err(MalformedBody("part has no header/body separator"))
    Some((idx, sep_len)) => {
      let header_block = slice_string(section, 0, idx)
      let mut body = slice_from(section, idx + sep_len)
      body = strip_one_trailing_newline(body)
      let headers = match
        parse_headers(header_block, options.max_headers_per_part) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      let disposition_header = match
        header_value(headers, "Content-Disposition") {
        Some(value) => value
        None =>
          return Err(InvalidContentDisposition("missing Content-Disposition"))
      }
      let disposition = match ContentDisposition::parse(disposition_header) {
        Ok(value) => value
        Err(err) => return Err(err)
      }
      if disposition.disposition != "form-data" {
        return Err(InvalidContentDisposition(disposition_header))
      }
      let name = match disposition.param("name") {
        Some(value) =>
          if value == "" {
            return Err(InvalidContentDisposition("empty part name"))
          } else {
            value
          }
        None => return Err(InvalidContentDisposition("missing part name"))
      }
      let filename = filename_from_disposition(disposition)
      Ok({
        name,
        filename,
        content_type: header_value(headers, "Content-Type"),
        headers,
        body,
      })
    }
  }
}

///|
fn parse_headers(
  block : String,
  max_headers : Int,
) -> Result[Array[(String, String)], MultipartError] {
  let headers = Array::new()
  let lines = block.replace_all(old="\r\n", new="\n").split("\n").collect()
  let mut i = 0
  while i < lines.length() {
    let line = lines[i].to_owned()
    if trim_ascii(line) != "" {
      match line.split_once(":") {
        Some((name_view, value_view)) => {
          let name = trim_ascii(name_view.to_owned())
          let value = trim_ascii(value_view.to_owned())
          if !is_safe_header_name(name) {
            return Err(InvalidHeader(line))
          }
          headers.push((name, value))
          if headers.length() > max_headers {
            return Err(
              LimitExceeded(
                "header count exceeds ParseOptions.max_headers_per_part",
              ),
            )
          }
        }
        None => return Err(InvalidHeader(line))
      }
    }
    i = i + 1
  }
  Ok(headers)
}

///|
fn header_value(headers : Array[(String, String)], name : String) -> String? {
  let mut i = 0
  while i < headers.length() {
    let (header_name, value) = headers[i]
    if header_name.compare_ignore_ascii_case(name) == 0 {
      return Some(value)
    }
    i = i + 1
  }
  None
}

///|
fn validate_boundary(boundary : String) -> Result[String, MultipartError] {
  if boundary == "" || boundary.length() > 70 {
    return Err(InvalidBoundary(boundary))
  }
  let mut i = 0
  while i < boundary.length() {
    let code = boundary[i]
    if !is_boundary_code_unit(code) {
      return Err(InvalidBoundary(boundary))
    }
    i = i + 1
  }
  Ok(boundary)
}

///|
fn split_header_parameters(header : String) -> Array[String] {
  let parts = Array::new()
  let current = Array::new()
  let mut quoted = false
  let mut escaped = false
  let mut i = 0
  while i < header.length() {
    let ch = char_at(header, i)
    if escaped {
      current.push(ch)
      escaped = false
    } else if quoted && ch == '\\' {
      current.push(ch)
      escaped = true
    } else if ch == '"' {
      current.push(ch)
      quoted = !quoted
    } else if !quoted && ch == ';' {
      parts.push(String::from_array(current))
      current.clear()
    } else {
      current.push(ch)
    }
    i = i + 1
  }
  parts.push(String::from_array(current))
  parts
}

///|
fn parse_parameter(raw : String) -> Result[(String, String), Unit] {
  match raw.split_once("=") {
    Some((name_view, value_view)) => {
      let name = trim_ascii(name_view.to_owned())
      if name == "" || !is_token(name) {
        return Err(())
      }
      let value = parse_parameter_value(trim_ascii(value_view.to_owned()))
      Ok((name, value))
    }
    None => Err(())
  }
}

///|
fn parse_parameter_value(value : String) -> String {
  if value.length() >= 2 && value[0] == 34 && value[value.length() - 1] == 34 {
    unescape_quoted(slice_string(value, 1, value.length() - 1))
  } else {
    value
  }
}

///|
fn find_param(params : Array[(String, String)], name : String) -> String? {
  let lower = to_lower_ascii(name)
  let mut i = 0
  while i < params.length() {
    let (key, value) = params[i]
    if to_lower_ascii(key) == lower {
      return Some(value)
    }
    i = i + 1
  }
  None
}

///|
fn strip_one_leading_newline(value : String) -> String {
  if value.has_prefix("\r\n") {
    slice_from(value, 2)
  } else if value.has_prefix("\n") {
    slice_from(value, 1)
  } else {
    value
  }
}

///|
fn strip_one_trailing_newline(value : String) -> String {
  if value.has_suffix("\r\n") {
    slice_string(value, 0, value.length() - 2)
  } else if value.has_suffix("\n") {
    slice_string(value, 0, value.length() - 1)
  } else {
    value
  }
}

///|
fn trim_ascii(value : String) -> String {
  value.trim(chars=" \t\r\n").to_owned()
}

///|
fn slice_string(value : String, start : Int, end : Int) -> String {
  value.unsafe_substring(start~, end~)
}

///|
fn slice_from(value : String, start : Int) -> String {
  value.unsafe_substring(start~, end=value.length())
}

///|
fn char_at(value : String, index : Int) -> Char {
  value.get_char(index).unwrap()
}

///|
fn to_lower_ascii(value : String) -> String {
  value.to_lower()
}

///|
fn escape_quoted(value : String) -> String {
  value.replace_all(old="\\", new="\\\\").replace_all(old="\"", new="\\\"")
}

///|
fn unescape_quoted(value : String) -> String {
  let chars = Array::new()
  let mut escaped = false
  let mut i = 0
  while i < value.length() {
    let ch = char_at(value, i)
    if escaped {
      chars.push(ch)
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else {
      chars.push(ch)
    }
    i = i + 1
  }
  if escaped {
    chars.push('\\')
  }
  String::from_array(chars)
}

///|
fn strip_header_linebreaks(value : String) -> String {
  value.replace_all(old="\r", new="").replace_all(old="\n", new="")
}

///|
fn display_snippet(value : String) -> String {
  value
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\r", new="\\r")
  .replace_all(old="\n", new="\\n")
}

///|
fn is_safe_header_name(name : String) -> Bool {
  if name == "" {
    return false
  }
  is_token(name)
}

///|
fn is_token(value : String) -> Bool {
  if value == "" {
    return false
  }
  let mut i = 0
  while i < value.length() {
    if !is_token_code_unit(value[i]) {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn is_token_code_unit(code : UInt16) -> Bool {
  (code >= 97 && code <= 122) ||
  (code >= 65 && code <= 90) ||
  (code >= 48 && code <= 57) ||
  code == 33 ||
  code == 35 ||
  code == 36 ||
  code == 37 ||
  code == 38 ||
  code == 39 ||
  code == 42 ||
  code == 43 ||
  code == 45 ||
  code == 46 ||
  code == 94 ||
  code == 95 ||
  code == 96 ||
  code == 124 ||
  code == 126
}

///|
fn is_boundary_code_unit(code : UInt16) -> Bool {
  (code >= 97 && code <= 122) ||
  (code >= 65 && code <= 90) ||
  (code >= 48 && code <= 57) ||
  code == 39 ||
  code == 40 ||
  code == 41 ||
  code == 43 ||
  code == 95 ||
  code == 44 ||
  code == 45 ||
  code == 46 ||
  code == 47 ||
  code == 58 ||
  code == 61 ||
  code == 63 ||
  code == 32
}
