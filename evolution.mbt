///|
/// Compatibility impact assigned to one upload contract change.
pub(all) enum ContractChangeImpact {
  CompatibleChange
  ReviewChange
  BreakingChange
} derive(Debug, Eq)

///|
/// One deterministic difference between two upload contracts.
pub(all) struct ContractChange {
  impact : ContractChangeImpact
  code : String
  path : String
  message : String
} derive(Debug, Eq)

///|
/// Ordered compatibility report for an old and a new upload contract.
pub(all) struct ContractDiff {
  changes : Array[ContractChange]
} derive(Debug, Eq)

///|
/// Compare two endpoint contracts and classify compatibility changes.
pub fn compare_upload_contracts(
  previous : UploadContract,
  current : UploadContract,
) -> ContractDiff {
  let changes = Array::new()
  compare_parse_options(previous.parse_options, current.parse_options, changes)
  compare_risk_ceiling(previous.max_risk, current.max_risk, changes)
  compare_schema_flags(previous.schema, current.schema, changes)
  compare_field_rules(previous.schema, current.schema, changes)
  compare_file_rules(previous.schema, current.schema, changes)
  { changes, }
}

///|
pub fn ContractChangeImpact::label(self : ContractChangeImpact) -> String {
  match self {
    CompatibleChange => "compatible"
    ReviewChange => "review"
    BreakingChange => "breaking"
  }
}

///|
pub fn ContractChange::to_line(self : ContractChange) -> String {
  self.impact.label() + "|" + self.code + "|" + self.path + "|" + self.message
}

///|
pub fn ContractDiff::is_unchanged(self : ContractDiff) -> Bool {
  self.changes.length() == 0
}

///|
pub fn ContractDiff::has_breaking_changes(self : ContractDiff) -> Bool {
  self.count_impact(BreakingChange) > 0
}

///|
pub fn ContractDiff::breaking_count(self : ContractDiff) -> Int {
  self.count_impact(BreakingChange)
}

///|
pub fn ContractDiff::review_count(self : ContractDiff) -> Int {
  self.count_impact(ReviewChange)
}

///|
pub fn ContractDiff::compatible_count(self : ContractDiff) -> Int {
  self.count_impact(CompatibleChange)
}

///|
pub fn ContractDiff::highest_impact(
  self : ContractDiff,
) -> ContractChangeImpact {
  if self.has_breaking_changes() {
    BreakingChange
  } else if self.review_count() > 0 {
    ReviewChange
  } else {
    CompatibleChange
  }
}

///|
pub fn ContractDiff::summary(self : ContractDiff) -> String {
  "contract-diff: breaking=" +
  self.breaking_count().to_string() +
  ", review=" +
  self.review_count().to_string() +
  ", compatible=" +
  self.compatible_count().to_string()
}

///|
pub fn ContractDiff::to_lines(self : ContractDiff) -> Array[String] {
  let lines = [self.summary()]
  let mut i = 0
  while i < self.changes.length() {
    lines.push(self.changes[i].to_line())
    i = i + 1
  }
  lines
}

///|
/// Render a review-friendly Markdown compatibility report.
pub fn ContractDiff::to_markdown(self : ContractDiff) -> String {
  let lines = [
    "# Upload contract compatibility report",
    "",
    self.summary(),
    "",
    "| Impact | Code | Path | Change |",
    "| --- | --- | --- | --- |",
  ]
  if self.changes.length() == 0 {
    lines.push("| compatible | unchanged | contract | No contract changes |")
  } else {
    let mut i = 0
    while i < self.changes.length() {
      let change = self.changes[i]
      lines.push(
        "| " +
        change.impact.label() +
        " | `" +
        change.code +
        "` | `" +
        change.path +
        "` | " +
        change.message +
        " |",
      )
      i = i + 1
    }
  }
  lines.join("\n")
}

///|
fn ContractDiff::count_impact(
  self : ContractDiff,
  impact : ContractChangeImpact,
) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.changes.length() {
    if self.changes[i].impact == impact {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
fn contract_change(
  impact : ContractChangeImpact,
  code : String,
  path : String,
  message : String,
) -> ContractChange {
  { impact, code, path, message }
}

///|
fn compare_parse_options(
  previous : ParseOptions,
  current : ParseOptions,
  changes : Array[ContractChange],
) -> Unit {
  compare_integer_ceiling(
    previous.max_parts,
    current.max_parts,
    "parse.max_parts",
    "max_parts",
    changes,
  )
  compare_integer_ceiling(
    previous.max_headers_per_part,
    current.max_headers_per_part,
    "parse.max_headers_per_part",
    "max_headers_per_part",
    changes,
  )
  compare_integer_ceiling(
    previous.max_body_length,
    current.max_body_length,
    "parse.max_body_length",
    "max_body_length",
    changes,
  )
}

///|
fn compare_integer_ceiling(
  previous : Int,
  current : Int,
  path : String,
  label : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  if current < previous {
    changes.push(
      contract_change(
        BreakingChange,
        "limit_tightened",
        path,
        label +
        " decreased from " +
        previous.to_string() +
        " to " +
        current.to_string(),
      ),
    )
  } else {
    changes.push(
      contract_change(
        CompatibleChange,
        "limit_relaxed",
        path,
        label +
        " increased from " +
        previous.to_string() +
        " to " +
        current.to_string(),
      ),
    )
  }
}

///|
fn compare_optional_ceiling(
  previous : Int,
  current : Int,
  path : String,
  label : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  let tightened = if previous < 0 {
    current >= 0
  } else if current < 0 {
    false
  } else {
    current < previous
  }
  let impact = if tightened { BreakingChange } else { CompatibleChange }
  let code = if tightened {
    "constraint_tightened"
  } else {
    "constraint_relaxed"
  }
  changes.push(
    contract_change(
      impact,
      code,
      path,
      label +
      " changed from " +
      limit_label(previous) +
      " to " +
      limit_label(current),
    ),
  )
}

///|
fn limit_label(value : Int) -> String {
  if value < 0 {
    "unlimited"
  } else {
    value.to_string()
  }
}

///|
fn compare_risk_ceiling(
  previous : UploadRisk,
  current : UploadRisk,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  if upload_risk_at_most(current, previous) {
    changes.push(
      contract_change(
        BreakingChange,
        "risk_ceiling_tightened",
        "risk.max",
        "accepted risk changed from " +
        previous.label() +
        " to " +
        current.label(),
      ),
    )
  } else {
    changes.push(
      contract_change(
        CompatibleChange,
        "risk_ceiling_relaxed",
        "risk.max",
        "accepted risk changed from " +
        previous.label() +
        " to " +
        current.label(),
      ),
    )
  }
}

///|
fn compare_schema_flags(
  previous : FormSchema,
  current : FormSchema,
  changes : Array[ContractChange],
) -> Unit {
  compare_unknown_flag(
    previous.allow_unknown_fields,
    current.allow_unknown_fields,
    "schema.unknown_fields",
    "field",
    changes,
  )
  compare_unknown_flag(
    previous.allow_unknown_files,
    current.allow_unknown_files,
    "schema.unknown_files",
    "file",
    changes,
  )
}

///|
fn compare_unknown_flag(
  previous : Bool,
  current : Bool,
  path : String,
  kind : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  if previous && !current {
    changes.push(
      contract_change(
        BreakingChange,
        "unknown_entries_rejected",
        path,
        "unknown " + kind + " names are now rejected",
      ),
    )
  } else {
    changes.push(
      contract_change(
        CompatibleChange,
        "unknown_entries_allowed",
        path,
        "unknown " + kind + " names are now allowed",
      ),
    )
  }
}

///|
fn compare_field_rules(
  previous : FormSchema,
  current : FormSchema,
  changes : Array[ContractChange],
) -> Unit {
  let mut i = 0
  while i < previous.field_rules.length() {
    let old_rule = previous.field_rules[i]
    match evolution_find_field_rule(current.field_rules, old_rule.name) {
      Some(new_rule) => compare_field_rule(old_rule, new_rule, changes)
      None => {
        let impact = if current.allow_unknown_fields {
          CompatibleChange
        } else {
          BreakingChange
        }
        changes.push(
          contract_change(
            impact,
            if impact == BreakingChange {
              "field_removed"
            } else {
              "field_rule_removed"
            },
            "schema.field." + old_rule.name,
            if impact == BreakingChange {
              "field is no longer accepted by the closed schema"
            } else {
              "field-specific restrictions were removed"
            },
          ),
        )
      }
    }
    i = i + 1
  }
  let mut j = 0
  while j < current.field_rules.length() {
    let rule = current.field_rules[j]
    if evolution_find_field_rule(previous.field_rules, rule.name) is None {
      let restrictive = rule.required ||
        (
          previous.allow_unknown_fields &&
          (rule.max_values >= 0 || rule.max_length >= 0 || !rule.allow_empty)
        )
      changes.push(
        contract_change(
          if restrictive {
            BreakingChange
          } else {
            CompatibleChange
          },
          if restrictive {
            "field_rule_added_restrictive"
          } else {
            "field_rule_added"
          },
          "schema.field." + rule.name,
          if rule.required {
            "new required field was added"
          } else if restrictive {
            "new field rule restricts a previously unknown field"
          } else {
            "new optional field is accepted"
          },
        ),
      )
    }
    j = j + 1
  }
}

///|
fn compare_field_rule(
  previous : FieldRule,
  current : FieldRule,
  changes : Array[ContractChange],
) -> Unit {
  let base = "schema.field." + previous.name
  compare_required(
    previous.required,
    current.required,
    base + ".required",
    "field",
    changes,
  )
  compare_optional_ceiling(
    previous.max_values,
    current.max_values,
    base + ".max_values",
    "max_values",
    changes,
  )
  compare_optional_ceiling(
    previous.max_length,
    current.max_length,
    base + ".max_length",
    "max_length",
    changes,
  )
  compare_allow_empty(
    previous.allow_empty,
    current.allow_empty,
    base + ".allow_empty",
    "field",
    changes,
  )
}

///|
fn compare_file_rules(
  previous : FormSchema,
  current : FormSchema,
  changes : Array[ContractChange],
) -> Unit {
  let mut i = 0
  while i < previous.file_rules.length() {
    let old_rule = previous.file_rules[i]
    match evolution_find_file_rule(current.file_rules, old_rule.name) {
      Some(new_rule) => compare_file_rule(old_rule, new_rule, changes)
      None => {
        let impact = if current.allow_unknown_files {
          CompatibleChange
        } else {
          BreakingChange
        }
        changes.push(
          contract_change(
            impact,
            if impact == BreakingChange {
              "file_removed"
            } else {
              "file_rule_removed"
            },
            "schema.file." + old_rule.name,
            if impact == BreakingChange {
              "file field is no longer accepted by the closed schema"
            } else {
              "file-specific restrictions were removed"
            },
          ),
        )
      }
    }
    i = i + 1
  }
  let mut j = 0
  while j < current.file_rules.length() {
    let rule = current.file_rules[j]
    if evolution_find_file_rule(previous.file_rules, rule.name) is None {
      let restrictive = rule.required ||
        (previous.allow_unknown_files && file_rule_has_restrictions(rule))
      changes.push(
        contract_change(
          if restrictive {
            BreakingChange
          } else {
            CompatibleChange
          },
          if restrictive {
            "file_rule_added_restrictive"
          } else {
            "file_rule_added"
          },
          "schema.file." + rule.name,
          if rule.required {
            "new required file field was added"
          } else if restrictive {
            "new file rule restricts a previously unknown file field"
          } else {
            "new optional file field is accepted"
          },
        ),
      )
    }
    j = j + 1
  }
}

///|
fn file_rule_has_restrictions(rule : FileRule) -> Bool {
  rule.max_files >= 0 ||
  rule.max_length >= 0 ||
  !rule.allow_empty ||
  rule.allowed_content_types.length() > 0 ||
  rule.allowed_extensions.length() > 0
}

///|
fn compare_file_rule(
  previous : FileRule,
  current : FileRule,
  changes : Array[ContractChange],
) -> Unit {
  let base = "schema.file." + previous.name
  compare_required(
    previous.required,
    current.required,
    base + ".required",
    "file",
    changes,
  )
  compare_optional_ceiling(
    previous.max_files,
    current.max_files,
    base + ".max_files",
    "max_files",
    changes,
  )
  compare_optional_ceiling(
    previous.max_length,
    current.max_length,
    base + ".max_length",
    "max_length",
    changes,
  )
  compare_allow_empty(
    previous.allow_empty,
    current.allow_empty,
    base + ".allow_empty",
    "file",
    changes,
  )
  compare_allow_list(
    previous.allowed_content_types,
    current.allowed_content_types,
    base + ".content_types",
    "content_type",
    changes,
  )
  compare_allow_list(
    previous.allowed_extensions,
    current.allowed_extensions,
    base + ".extensions",
    "extension",
    changes,
  )
}

///|
fn compare_required(
  previous : Bool,
  current : Bool,
  path : String,
  kind : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  if !previous && current {
    changes.push(
      contract_change(
        BreakingChange,
        "required_added",
        path,
        kind + " is now required",
      ),
    )
  } else {
    changes.push(
      contract_change(
        CompatibleChange,
        "required_removed",
        path,
        kind + " is now optional",
      ),
    )
  }
}

///|
fn compare_allow_empty(
  previous : Bool,
  current : Bool,
  path : String,
  kind : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous == current {
    return
  }
  if previous && !current {
    changes.push(
      contract_change(
        BreakingChange,
        "empty_rejected",
        path,
        "empty " + kind + " values are now rejected",
      ),
    )
  } else {
    changes.push(
      contract_change(
        CompatibleChange,
        "empty_allowed",
        path,
        "empty " + kind + " values are now allowed",
      ),
    )
  }
}

///|
fn compare_allow_list(
  previous : Array[String],
  current : Array[String],
  path : String,
  item_name : String,
  changes : Array[ContractChange],
) -> Unit {
  if previous.length() == 0 && current.length() == 0 {
    return
  }
  if previous.length() == 0 {
    changes.push(
      contract_change(
        BreakingChange,
        "allowlist_introduced",
        path,
        item_name + " allowlist now restricts previously accepted values",
      ),
    )
    return
  }
  if current.length() == 0 {
    changes.push(
      contract_change(
        CompatibleChange,
        "allowlist_removed",
        path,
        item_name + " allowlist was removed",
      ),
    )
    return
  }
  let mut i = 0
  while i < previous.length() {
    if !evolution_contains_ignore_case(current, previous[i]) {
      changes.push(
        contract_change(
          BreakingChange,
          "allowlist_value_removed",
          path,
          item_name + " is no longer accepted: " + previous[i],
        ),
      )
    }
    i = i + 1
  }
  let mut j = 0
  while j < current.length() {
    if !evolution_contains_ignore_case(previous, current[j]) {
      changes.push(
        contract_change(
          CompatibleChange,
          "allowlist_value_added",
          path,
          item_name + " is now accepted: " + current[j],
        ),
      )
    }
    j = j + 1
  }
}

///|
fn evolution_find_field_rule(
  rules : Array[FieldRule],
  name : String,
) -> FieldRule? {
  let mut i = 0
  while i < rules.length() {
    if rules[i].name == name {
      return Some(rules[i])
    }
    i = i + 1
  }
  None
}

///|
fn evolution_find_file_rule(
  rules : Array[FileRule],
  name : String,
) -> FileRule? {
  let mut i = 0
  while i < rules.length() {
    if rules[i].name == name {
      return Some(rules[i])
    }
    i = i + 1
  }
  None
}

///|
fn evolution_contains_ignore_case(
  values : Array[String],
  target : String,
) -> Bool {
  let mut i = 0
  while i < values.length() {
    if values[i].compare_ignore_ascii_case(target) == 0 {
      return true
    }
    i = i + 1
  }
  false
}
