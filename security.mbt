///|
pub(all) struct FilenamePolicy {
  fallback : String
  max_length : Int
  allow_leading_dot : Bool
  allow_spaces : Bool
  allowed_extensions : Array[String]
  blocked_extensions : Array[String]
} derive(Debug, Eq)

///|
pub fn default_filename_policy() -> FilenamePolicy {
  {
    fallback: "upload.bin",
    max_length: 120,
    allow_leading_dot: false,
    allow_spaces: true,
    allowed_extensions: [],
    blocked_extensions: [
      "exe", "bat", "cmd", "com", "scr", "ps1", "sh", "dll", "so",
    ],
  }
}

///|
pub fn strict_filename_policy() -> FilenamePolicy {
  {
    fallback: "upload.bin",
    max_length: 80,
    allow_leading_dot: false,
    allow_spaces: false,
    allowed_extensions: [],
    blocked_extensions: [
      "exe", "bat", "cmd", "com", "scr", "ps1", "sh", "dll", "so", "js",
    ],
  }
}

///|
pub fn image_filename_policy() -> FilenamePolicy {
  {
    fallback: "upload.bin",
    max_length: 120,
    allow_leading_dot: false,
    allow_spaces: true,
    allowed_extensions: ["png", "jpg", "jpeg", "gif", "webp", "svg"],
    blocked_extensions: [],
  }
}

///|
pub fn sanitize_filename_with_policy(
  filename : String,
  policy : FilenamePolicy,
) -> String {
  let cleaned = safe_filename(filename)
  let chars = Array::new()
  let mut i = 0
  while i < cleaned.length() {
    let code = cleaned[i]
    if code == 32 && !policy.allow_spaces {
      chars.push('_')
    } else if is_filename_policy_char(code) {
      chars.push(char_at(cleaned, i))
    } else {
      chars.push('_')
    }
    i = i + 1
  }
  let mut out = trim_ascii(String::from_array(chars))
  if out == "" || out == "." || out == ".." {
    out = policy.fallback
  }
  if !policy.allow_leading_dot {
    while out.has_prefix(".") {
      out = slice_from(out, 1)
    }
    if out == "" {
      out = policy.fallback
    }
  }
  if out.length() > policy.max_length && policy.max_length > 0 {
    out = shorten_filename(out, policy.max_length)
  }
  if policy.allowed_extensions.length() > 0 &&
    !filename_has_allowed_extension(out, policy.allowed_extensions) {
    out = append_extension_if_missing(out, "bin")
  }
  if policy.blocked_extensions.length() > 0 &&
    filename_has_allowed_extension(out, policy.blocked_extensions) {
    out = out + ".upload"
  }
  out
}

///|
pub fn filename_extension(filename : String) -> String? {
  let safe = safe_filename(filename)
  match safe.rev_split_once(".") {
    Some((head, tail)) =>
      if head.to_owned() == "" || tail.to_owned() == "" {
        None
      } else {
        Some(to_lower_ascii(tail.to_owned()))
      }
    None => None
  }
}

///|
pub fn filename_stem(filename : String) -> String {
  let safe = safe_filename(filename)
  match safe.rev_split_once(".") {
    Some((head, tail)) =>
      if head.to_owned() == "" || tail.to_owned() == "" {
        safe
      } else {
        head.to_owned()
      }
    None => safe
  }
}

///|
pub fn filename_has_extension(filename : String, extension : String) -> Bool {
  match filename_extension(filename) {
    Some(actual) => actual == normalize_extension(extension)
    None => false
  }
}

///|
pub fn filename_has_allowed_extension(
  filename : String,
  allowed : Array[String],
) -> Bool {
  if allowed.length() == 0 {
    return true
  }
  match filename_extension(filename) {
    Some(actual) => {
      let mut i = 0
      while i < allowed.length() {
        if actual == normalize_extension(allowed[i]) {
          return true
        }
        i = i + 1
      }
      false
    }
    None => false
  }
}

///|
pub fn filename_contains_path_separator(filename : String) -> Bool {
  filename.find("/") is Some(_) || filename.find("\\") is Some(_)
}

///|
pub fn filename_looks_like_windows_drive(filename : String) -> Bool {
  filename.length() >= 2 &&
  is_ascii_alpha_code(filename[0]) &&
  filename[1] == 58
}

///|
pub fn filename_has_control_chars(filename : String) -> Bool {
  let mut i = 0
  while i < filename.length() {
    let code = filename[i]
    if code < 32 || code == 127 {
      return true
    }
    i = i + 1
  }
  false
}

///|
pub fn filename_security_notes(filename : String) -> Array[String] {
  let notes = Array::new()
  if filename_contains_path_separator(filename) {
    notes.push("path separator removed")
  }
  if filename_looks_like_windows_drive(filename) {
    notes.push("windows drive prefix removed")
  }
  if filename_has_control_chars(filename) {
    notes.push("control characters removed")
  }
  if safe_filename(filename) != filename {
    notes.push("filename normalized")
  }
  notes
}

///|
fn shorten_filename(filename : String, max_length : Int) -> String {
  if filename.length() <= max_length {
    return filename
  }
  match filename_extension(filename) {
    Some(ext) => {
      let suffix = "." + ext
      let budget = max_length - suffix.length()
      if budget <= 0 {
        slice_string(filename, 0, max_length)
      } else {
        slice_string(filename_stem(filename), 0, budget) + suffix
      }
    }
    None => slice_string(filename, 0, max_length)
  }
}

///|
fn append_extension_if_missing(filename : String, extension : String) -> String {
  match filename_extension(filename) {
    Some(_) => filename
    None => filename + "." + normalize_extension(extension)
  }
}

///|
fn normalize_extension(extension : String) -> String {
  let trimmed = trim_ascii(extension)
  if trimmed.has_prefix(".") {
    to_lower_ascii(slice_from(trimmed, 1))
  } else {
    to_lower_ascii(trimmed)
  }
}

///|
fn is_filename_policy_char(code : UInt16) -> Bool {
  code >= 32 && code != 47 && code != 92 && code != 58
}

///|
fn is_ascii_alpha_code(code : UInt16) -> Bool {
  (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
}
