///|
pub fn is_multipart_form_data_content_type(header : String) -> Bool {
  match MediaType::parse(header) {
    Ok(media) => media.typ == "multipart" && media.subtype == "form-data"
    Err(_) => false
  }
}

///|
pub fn media_type_without_params(
  header : String,
) -> Result[String, MultipartError] {
  match MediaType::parse(header) {
    Ok(media) => Ok(media.typ + "/" + media.subtype)
    Err(err) => Err(err)
  }
}

///|
pub fn format_media_type(media : MediaType) -> String {
  let pieces = Array::new()
  pieces.push(media.typ + "/" + media.subtype)
  let mut i = 0
  while i < media.params.length() {
    let (name, value) = media.params[i]
    pieces.push(name + "=" + quote_header_value(value))
    i = i + 1
  }
  pieces.join("; ")
}

///|
pub fn format_content_disposition(disposition : ContentDisposition) -> String {
  let pieces = Array::new()
  pieces.push(disposition.disposition)
  let mut i = 0
  while i < disposition.params.length() {
    let (name, value) = disposition.params[i]
    pieces.push(name + "=" + quote_header_value(value))
    i = i + 1
  }
  pieces.join("; ")
}

///|
pub fn quote_header_value(value : String) -> String {
  if is_token(value) {
    value
  } else {
    "\"" + escape_quoted(value) + "\""
  }
}

///|
pub fn normalize_header_name(name : String) -> String {
  let out = Array::new()
  let mut upper_next = true
  let mut i = 0
  while i < name.length() {
    let code = name[i]
    if code == 45 {
      out.push('-')
      upper_next = true
    } else if upper_next {
      out.push(upper_ascii_char(code))
      upper_next = false
    } else {
      out.push(lower_ascii_char(code))
    }
    i = i + 1
  }
  String::from_array(out)
}

///|
pub fn header_names(headers : Array[(String, String)]) -> Array[String] {
  let names = Array::new()
  let mut i = 0
  while i < headers.length() {
    let (name, _) = headers[i]
    names.push(name)
    i = i + 1
  }
  names
}

///|
pub fn has_header(headers : Array[(String, String)], name : String) -> Bool {
  header_value(headers, name) is Some(_)
}

///|
pub fn remove_header(
  headers : Array[(String, String)],
  name : String,
) -> Array[(String, String)] {
  let out = Array::new()
  let mut i = 0
  while i < headers.length() {
    let (header_name, value) = headers[i]
    if header_name.compare_ignore_ascii_case(name) != 0 {
      out.push((header_name, value))
    }
    i = i + 1
  }
  out
}

///|
pub fn set_header(
  headers : Array[(String, String)],
  name : String,
  value : String,
) -> Result[Array[(String, String)], MultipartError] {
  if !is_safe_header_name(name) {
    return Err(InvalidHeader(name))
  }
  let out = Array::new()
  let mut replaced = false
  let mut i = 0
  while i < headers.length() {
    let (header_name, header_value) = headers[i]
    if header_name.compare_ignore_ascii_case(name) == 0 {
      out.push((header_name, strip_header_linebreaks(value)))
      replaced = true
    } else {
      out.push((header_name, header_value))
    }
    i = i + 1
  }
  if !replaced {
    out.push((name, strip_header_linebreaks(value)))
  }
  Ok(out)
}

///|
pub fn parse_content_disposition_header(
  value : String,
) -> Result[ContentDisposition, MultipartError] {
  ContentDisposition::parse(value)
}

///|
pub fn parse_media_type_header(
  value : String,
) -> Result[MediaType, MultipartError] {
  MediaType::parse(value)
}

///|
pub fn filename_from_disposition(disposition : ContentDisposition) -> String? {
  match disposition.param("filename*") {
    Some(value) =>
      match decode_rfc5987_value(value) {
        Ok(decoded) => Some(safe_filename(decoded))
        Err(_) =>
          match disposition.param("filename") {
            Some(fallback) => Some(safe_filename(fallback))
            None => None
          }
      }
    None =>
      match disposition.param("filename") {
        Some(value) => Some(safe_filename(value))
        None => None
      }
  }
}

///|
pub fn decode_rfc5987_value(value : String) -> Result[String, MultipartError] {
  match value.split_once("''") {
    Some((charset_view, encoded_view)) => {
      let charset = to_lower_ascii(charset_view.to_owned())
      if charset != "utf-8" && charset != "us-ascii" {
        return Err(InvalidContentDisposition(value))
      }
      decode_percent_ascii(encoded_view.to_owned())
    }
    None => decode_percent_ascii(value)
  }
}

///|
pub fn encode_rfc5987_value(value : String) -> String {
  "UTF-8''" + percent_encode_header_value(value)
}

///|
pub fn percent_encode_header_value(value : String) -> String {
  let out = Array::new()
  let mut i = 0
  while i < value.length() {
    let code = value[i]
    if is_rfc5987_attr_char(code) {
      out.push(char_at(value, i))
    } else {
      out.push('%')
      out.push(hex_digit((code.to_int() >> 4) & 15))
      out.push(hex_digit(code.to_int() & 15))
    }
    i = i + 1
  }
  String::from_array(out)
}

///|
pub fn decode_percent_ascii(value : String) -> Result[String, MultipartError] {
  let out = Array::new()
  let mut i = 0
  while i < value.length() {
    let code = value[i]
    if code == 37 {
      if i + 2 >= value.length() {
        return Err(InvalidContentDisposition(value))
      }
      let hi = hex_value(value[i + 1])
      let lo = hex_value(value[i + 2])
      if hi < 0 || lo < 0 {
        return Err(InvalidContentDisposition(value))
      }
      out.push((hi * 16 + lo : Int).unsafe_to_char())
      i = i + 3
    } else {
      out.push(char_at(value, i))
      i = i + 1
    }
  }
  Ok(String::from_array(out))
}

///|
fn hex_value(code : UInt16) -> Int {
  if code >= 48 && code <= 57 {
    code.to_int() - 48
  } else if code >= 65 && code <= 70 {
    code.to_int() - 55
  } else if code >= 97 && code <= 102 {
    code.to_int() - 87
  } else {
    -1
  }
}

///|
fn hex_digit(value : Int) -> Char {
  if value >= 0 && value <= 9 {
    (value + 48).unsafe_to_char()
  } else {
    (value - 10 + 65).unsafe_to_char()
  }
}

///|
fn upper_ascii_char(code : UInt16) -> Char {
  if code >= 97 && code <= 122 {
    (code.to_int() - 32).unsafe_to_char()
  } else {
    code.unsafe_to_char()
  }
}

///|
fn lower_ascii_char(code : UInt16) -> Char {
  if code >= 65 && code <= 90 {
    (code.to_int() + 32).unsafe_to_char()
  } else {
    code.unsafe_to_char()
  }
}

///|
fn is_rfc5987_attr_char(code : UInt16) -> Bool {
  (code >= 48 && code <= 57) ||
  (code >= 65 && code <= 90) ||
  (code >= 97 && code <= 122) ||
  code == 33 ||
  code == 35 ||
  code == 36 ||
  code == 38 ||
  code == 43 ||
  code == 45 ||
  code == 46 ||
  code == 94 ||
  code == 95 ||
  code == 96 ||
  code == 124 ||
  code == 126
}
