///|
pub(all) enum UploadRisk {
  LowRisk
  MediumRisk
  HighRisk
} derive(Debug, Eq)

///|
pub(all) enum BodySizeClass {
  EmptyBody
  TinyBody
  SmallBody
  MediumBody
  LargeBody
} derive(Debug, Eq)

///|
pub(all) struct NameCount {
  name : String
  count : Int
} derive(Debug, Eq)

///|
pub(all) struct FieldProfile {
  name : String
  values : Int
  total_length : Int
  max_length : Int
  empty_values : Int
  duplicated : Bool
  size_class : BodySizeClass
} derive(Debug, Eq)

///|
pub(all) struct FileProfile {
  name : String
  filename : String
  content_type : String
  length : Int
  empty : Bool
  extension : String?
  risk : UploadRisk
  notes : Array[String]
  size_class : BodySizeClass
} derive(Debug, Eq)

///|
pub(all) struct HeaderProfile {
  name : String
  count : Int
  first_value : String
} derive(Debug, Eq)

///|
pub(all) struct FormAnalysis {
  summary : FormSummary
  fields : Array[FieldProfile]
  files : Array[FileProfile]
  content_types : Array[NameCount]
  headers : Array[HeaderProfile]
  risk : UploadRisk
  notes : Array[String]
} derive(Debug, Eq)

///|
pub fn analyze_form(form : MultipartForm) -> FormAnalysis {
  let fields = analyze_fields(form)
  let files = analyze_files(form)
  let content_types = analyze_content_types(form)
  let headers = analyze_headers(form)
  let notes = analysis_notes(form, fields, files)
  let risk = analysis_risk(form, fields, files, notes)
  {
    summary: form.summary(),
    fields,
    files,
    content_types,
    headers,
    risk,
    notes,
  }
}

///|
pub fn analyze_request(
  request : MultipartRequest,
) -> Result[FormAnalysis, MultipartError] {
  match roundtrip_request(request) {
    Ok(form) => Ok(analyze_form(form))
    Err(err) => Err(err)
  }
}

///|
pub fn request_analysis_lines(
  request : MultipartRequest,
) -> Result[Array[String], MultipartError] {
  match analyze_request(request) {
    Ok(analysis) => Ok(analysis.to_lines())
    Err(err) => Err(err)
  }
}

///|
pub fn FormAnalysis::compact_line(self : FormAnalysis) -> String {
  self.summary.to_line() +
  ", risk=" +
  self.risk.label() +
  ", notes=" +
  self.notes.length().to_string()
}

///|
pub fn FormAnalysis::to_lines(self : FormAnalysis) -> Array[String] {
  let lines = Array::new()
  lines.push("MoonFormData analysis")
  lines.push(self.compact_line())
  lines.push("fields=" + self.fields.length().to_string())
  let mut i = 0
  while i < self.fields.length() {
    lines.push("field " + self.fields[i].to_line())
    i = i + 1
  }
  lines.push("files=" + self.files.length().to_string())
  let mut j = 0
  while j < self.files.length() {
    lines.push("file " + self.files[j].to_line())
    j = j + 1
  }
  if self.content_types.length() > 0 {
    lines.push("content-types=" + format_name_counts(self.content_types))
  }
  if self.headers.length() > 0 {
    lines.push("headers=" + self.headers.length().to_string())
  }
  let mut n = 0
  while n < self.notes.length() {
    lines.push("note " + self.notes[n])
    n = n + 1
  }
  lines
}

///|
pub fn FormAnalysis::has_note(self : FormAnalysis, needle : String) -> Bool {
  let mut i = 0
  while i < self.notes.length() {
    if self.notes[i].find(needle) is Some(_) {
      return true
    }
    i = i + 1
  }
  false
}

///|
pub fn FormAnalysis::is_low_risk(self : FormAnalysis) -> Bool {
  self.risk == LowRisk
}

///|
pub fn FormAnalysis::is_high_risk(self : FormAnalysis) -> Bool {
  self.risk == HighRisk
}

///|
pub fn FieldProfile::to_line(self : FieldProfile) -> String {
  self.name +
  ": values=" +
  self.values.to_string() +
  ", total=" +
  self.total_length.to_string() +
  ", max=" +
  self.max_length.to_string() +
  ", empty=" +
  self.empty_values.to_string() +
  ", duplicate=" +
  self.duplicated.to_string() +
  ", size=" +
  self.size_class.label()
}

///|
pub fn FileProfile::to_line(self : FileProfile) -> String {
  self.name +
  ": filename=" +
  self.filename +
  ", type=" +
  self.content_type +
  ", bytes=" +
  self.length.to_string() +
  ", empty=" +
  self.empty.to_string() +
  ", risk=" +
  self.risk.label() +
  ", size=" +
  self.size_class.label()
}

///|
pub fn HeaderProfile::to_line(self : HeaderProfile) -> String {
  self.name +
  ": count=" +
  self.count.to_string() +
  ", first=" +
  self.first_value
}

///|
pub fn UploadRisk::label(self : UploadRisk) -> String {
  match self {
    LowRisk => "low"
    MediumRisk => "medium"
    HighRisk => "high"
  }
}

///|
pub fn BodySizeClass::label(self : BodySizeClass) -> String {
  match self {
    EmptyBody => "empty"
    TinyBody => "tiny"
    SmallBody => "small"
    MediumBody => "medium"
    LargeBody => "large"
  }
}

///|
pub fn body_size_class(length : Int) -> BodySizeClass {
  if length <= 0 {
    EmptyBody
  } else if length <= 1024 {
    TinyBody
  } else if length <= 1024 * 64 {
    SmallBody
  } else if length <= 1024 * 1024 {
    MediumBody
  } else {
    LargeBody
  }
}

///|
pub fn count_by_name(values : Array[String]) -> Array[NameCount] {
  let counts = Array::new()
  let mut i = 0
  while i < values.length() {
    increment_name_count(counts, values[i])
    i = i + 1
  }
  counts
}

///|
pub fn find_name_count(counts : Array[NameCount], name : String) -> Int {
  let mut i = 0
  while i < counts.length() {
    if counts[i].name == name {
      return counts[i].count
    }
    i = i + 1
  }
  0
}

///|
pub fn form_name_counts(form : MultipartForm) -> Array[NameCount] {
  let names = Array::new()
  let mut i = 0
  while i < form.parts.length() {
    names.push(form.parts[i].name)
    i = i + 1
  }
  count_by_name(names)
}

///|
pub fn form_content_type_counts(form : MultipartForm) -> Array[NameCount] {
  analyze_content_types(form)
}

///|
pub fn detect_boundary_in_part_bodies(form : MultipartForm) -> Bool {
  let marker = "--" + form.boundary
  let mut i = 0
  while i < form.parts.length() {
    if form.parts[i].body.find(marker) is Some(_) {
      return true
    }
    i = i + 1
  }
  false
}

///|
fn analyze_fields(form : MultipartForm) -> Array[FieldProfile] {
  let names = form.field_names()
  let fields = Array::new()
  let mut i = 0
  while i < names.length() {
    fields.push(field_profile(form, names[i]))
    i = i + 1
  }
  fields
}

///|
fn field_profile(form : MultipartForm, name : String) -> FieldProfile {
  let values = form.field_values(name)
  let mut total = 0
  let mut max = 0
  let mut empty = 0
  let mut i = 0
  while i < values.length() {
    let len = values[i].length()
    total = total + len
    if len > max {
      max = len
    }
    if len == 0 {
      empty = empty + 1
    }
    i = i + 1
  }
  {
    name,
    values: values.length(),
    total_length: total,
    max_length: max,
    empty_values: empty,
    duplicated: values.length() > 1,
    size_class: body_size_class(max),
  }
}

///|
fn analyze_files(form : MultipartForm) -> Array[FileProfile] {
  let profiles = Array::new()
  let files = form.file_parts()
  let mut i = 0
  while i < files.length() {
    profiles.push(file_profile(files[i]))
    i = i + 1
  }
  profiles
}

///|
fn file_profile(part : FormPart) -> FileProfile {
  let filename = part.filename.unwrap_or("upload.bin")
  let content_type = part.content_type.unwrap_or("application/octet-stream")
  let notes = filename_security_notes(filename)
  let extension = filename_extension(filename)
  let risk = file_risk(part, filename, content_type, notes)
  {
    name: part.name,
    filename,
    content_type,
    length: part.body.length(),
    empty: part.body.length() == 0,
    extension,
    risk,
    notes,
    size_class: body_size_class(part.body.length()),
  }
}

///|
fn file_risk(
  part : FormPart,
  filename : String,
  content_type : String,
  notes : Array[String],
) -> UploadRisk {
  let ext = filename_extension(filename).unwrap_or("")
  if notes.length() > 0 ||
    is_known_executable_extension(ext) ||
    content_type == "application/x-msdownload" {
    HighRisk
  } else if part.body.length() == 0 ||
    content_type == "application/octet-stream" ||
    ext == "" {
    MediumRisk
  } else {
    LowRisk
  }
}

///|
fn is_known_executable_extension(ext : String) -> Bool {
  ext == "exe" ||
  ext == "bat" ||
  ext == "cmd" ||
  ext == "com" ||
  ext == "scr" ||
  ext == "ps1" ||
  ext == "sh" ||
  ext == "dll" ||
  ext == "so" ||
  ext == "js"
}

///|
fn analyze_content_types(form : MultipartForm) -> Array[NameCount] {
  let values = Array::new()
  let files = form.file_parts()
  let mut i = 0
  while i < files.length() {
    values.push(files[i].content_type.unwrap_or("application/octet-stream"))
    i = i + 1
  }
  count_by_name(values)
}

///|
fn analyze_headers(form : MultipartForm) -> Array[HeaderProfile] {
  let profiles = Array::new()
  let mut p = 0
  while p < form.parts.length() {
    let headers = form.parts[p].headers
    let mut h = 0
    while h < headers.length() {
      let (name, value) = headers[h]
      increment_header_profile(profiles, normalize_header_name(name), value)
      h = h + 1
    }
    p = p + 1
  }
  profiles
}

///|
fn analysis_notes(
  form : MultipartForm,
  fields : Array[FieldProfile],
  files : Array[FileProfile],
) -> Array[String] {
  let notes = Array::new()
  if form.parts.length() == 0 {
    notes.push("form has no parts")
  }
  if detect_boundary_in_part_bodies(form) {
    notes.push("part body contains the active boundary marker")
  }
  let mut i = 0
  while i < fields.length() {
    if fields[i].duplicated {
      notes.push("duplicate text field: " + fields[i].name)
    }
    if fields[i].empty_values > 0 {
      notes.push("empty text field value: " + fields[i].name)
    }
    i = i + 1
  }
  let mut j = 0
  while j < files.length() {
    if files[j].empty {
      notes.push("empty file: " + files[j].name)
    }
    let mut n = 0
    while n < files[j].notes.length() {
      notes.push("filename " + files[j].notes[n] + ": " + files[j].filename)
      n = n + 1
    }
    if files[j].risk == HighRisk {
      notes.push("high risk file: " + files[j].filename)
    }
    j = j + 1
  }
  notes
}

///|
fn analysis_risk(
  form : MultipartForm,
  fields : Array[FieldProfile],
  files : Array[FileProfile],
  notes : Array[String],
) -> UploadRisk {
  let mut risk = LowRisk
  if form.parts.length() == 0 || notes.length() > 0 {
    risk = max_risk(risk, MediumRisk)
  }
  if detect_boundary_in_part_bodies(form) {
    risk = max_risk(risk, HighRisk)
  }
  let mut i = 0
  while i < fields.length() {
    if fields[i].size_class == LargeBody {
      risk = max_risk(risk, HighRisk)
    } else if fields[i].size_class == MediumBody {
      risk = max_risk(risk, MediumRisk)
    }
    i = i + 1
  }
  let mut j = 0
  while j < files.length() {
    risk = max_risk(risk, files[j].risk)
    if files[j].size_class == LargeBody {
      risk = max_risk(risk, HighRisk)
    }
    j = j + 1
  }
  risk
}

///|
fn max_risk(a : UploadRisk, b : UploadRisk) -> UploadRisk {
  if risk_rank(a) >= risk_rank(b) {
    a
  } else {
    b
  }
}

///|
fn risk_rank(risk : UploadRisk) -> Int {
  match risk {
    LowRisk => 1
    MediumRisk => 2
    HighRisk => 3
  }
}

///|
fn increment_name_count(counts : Array[NameCount], name : String) -> Unit {
  let mut i = 0
  while i < counts.length() {
    if counts[i].name == name {
      let current = counts[i]
      counts[i] = { name: current.name, count: current.count + 1 }
      return
    }
    i = i + 1
  }
  counts.push({ name, count: 1 })
}

///|
fn increment_header_profile(
  profiles : Array[HeaderProfile],
  name : String,
  value : String,
) -> Unit {
  let mut i = 0
  while i < profiles.length() {
    if profiles[i].name.compare_ignore_ascii_case(name) == 0 {
      let current = profiles[i]
      profiles[i] = {
        name: current.name,
        count: current.count + 1,
        first_value: current.first_value,
      }
      return
    }
    i = i + 1
  }
  profiles.push({ name, count: 1, first_value: value })
}

///|
fn format_name_counts(counts : Array[NameCount]) -> String {
  let pieces = Array::new()
  let mut i = 0
  while i < counts.length() {
    pieces.push(counts[i].name + "=" + counts[i].count.to_string())
    i = i + 1
  }
  pieces.join(", ")
}
