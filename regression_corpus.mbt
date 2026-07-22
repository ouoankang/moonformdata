///|
pub(all) struct RegressionFixtureSpec {
  label : String
  boundary : String
  title : String
  tag : String
  filename : String
  file_body : String
} derive(Debug, Eq)

///|
pub fn regression_fixture_from_spec(
  spec : RegressionFixtureSpec,
) -> MultipartFixture {
  {
    name: spec.label,
    boundary: spec.boundary,
    body: "--" +
    spec.boundary +
    "\r\n" +
    "Content-Disposition: form-data; name=\"title\"\r\n" +
    "\r\n" +
    spec.title +
    "\r\n" +
    "--" +
    spec.boundary +
    "\r\n" +
    "Content-Disposition: form-data; name=\"tag\"\r\n" +
    "\r\n" +
    spec.tag +
    "\r\n" +
    "--" +
    spec.boundary +
    "\r\n" +
    "Content-Disposition: form-data; name=\"upload\"; filename=\"" +
    spec.filename +
    "\"\r\n" +
    "Content-Type: text/plain\r\n" +
    "\r\n" +
    spec.file_body +
    "\r\n" +
    "--" +
    spec.boundary +
    "--\r\n",
    expected_parts: 3,
    expected_fields: 2,
    expected_files: 1,
  }
}

///|
pub fn regression_specs() -> Array[RegressionFixtureSpec] {
  [
    {
      label: "case 001 api upload",
      boundary: "case001",
      title: "api upload",
      tag: "api",
      filename: "api-upload.txt",
      file_body: "payload-001",
    },
    {
      label: "case 002 webhook json",
      boundary: "case002",
      title: "webhook json",
      tag: "webhook",
      filename: "event.json",
      file_body: "{\"ok\":true}",
    },
    {
      label: "case 003 cli report",
      boundary: "case003",
      title: "cli report",
      tag: "cli",
      filename: "report.txt",
      file_body: "report body",
    },
    {
      label: "case 004 gateway trace",
      boundary: "case004",
      title: "gateway trace",
      tag: "gateway",
      filename: "trace.txt",
      file_body: "trace body",
    },
    {
      label: "case 005 form submit",
      boundary: "case005",
      title: "form submit",
      tag: "form",
      filename: "submit.txt",
      file_body: "submit body",
    },
    {
      label: "case 006 empty safe",
      boundary: "case006",
      title: "empty safe",
      tag: "empty",
      filename: "empty.txt",
      file_body: "",
    },
    {
      label: "case 007 duplicate name",
      boundary: "case007",
      title: "duplicate name",
      tag: "duplicate",
      filename: "duplicate.txt",
      file_body: "duplicate body",
    },
    {
      label: "case 008 long title",
      boundary: "case008",
      title: "long title for multipart regression",
      tag: "long",
      filename: "long-title.txt",
      file_body: "long body",
    },
    {
      label: "case 009 spaces filename",
      boundary: "case009",
      title: "spaces filename",
      tag: "filename",
      filename: "space name.txt",
      file_body: "space body",
    },
    {
      label: "case 010 dash boundary",
      boundary: "case-010",
      title: "dash boundary",
      tag: "boundary",
      filename: "dash.txt",
      file_body: "dash body",
    },
    {
      label: "case 011 underscore boundary",
      boundary: "case_011",
      title: "underscore boundary",
      tag: "boundary",
      filename: "underscore.txt",
      file_body: "underscore body",
    },
    {
      label: "case 012 dot boundary",
      boundary: "case.012",
      title: "dot boundary",
      tag: "boundary",
      filename: "dot.txt",
      file_body: "dot body",
    },
    {
      label: "case 013 numeric values",
      boundary: "case013",
      title: "123",
      tag: "456",
      filename: "numbers.txt",
      file_body: "789",
    },
    {
      label: "case 014 uppercase text",
      boundary: "case014",
      title: "UPPER",
      tag: "CASE",
      filename: "upper.txt",
      file_body: "BODY",
    },
    {
      label: "case 015 lowercase text",
      boundary: "case015",
      title: "lower",
      tag: "case",
      filename: "lower.txt",
      file_body: "body",
    },
    {
      label: "case 016 mixed case",
      boundary: "case016",
      title: "Mixed Case",
      tag: "MiXeD",
      filename: "mixed.txt",
      file_body: "MiXeD body",
    },
    {
      label: "case 017 csv file",
      boundary: "case017",
      title: "csv file",
      tag: "csv",
      filename: "data.csv",
      file_body: "a,b,c",
    },
    {
      label: "case 018 markdown file",
      boundary: "case018",
      title: "markdown file",
      tag: "md",
      filename: "readme.md",
      file_body: "# title",
    },
    {
      label: "case 019 log file",
      boundary: "case019",
      title: "log file",
      tag: "log",
      filename: "app.log",
      file_body: "INFO ok",
    },
    {
      label: "case 020 config file",
      boundary: "case020",
      title: "config file",
      tag: "config",
      filename: "config.toml",
      file_body: "name='demo'",
    },
    {
      label: "case 021 html sample",
      boundary: "case021",
      title: "html sample",
      tag: "html",
      filename: "page.html",
      file_body: "<h1>ok</h1>",
    },
    {
      label: "case 022 xml sample",
      boundary: "case022",
      title: "xml sample",
      tag: "xml",
      filename: "doc.xml",
      file_body: "<root/>",
    },
    {
      label: "case 023 yaml sample",
      boundary: "case023",
      title: "yaml sample",
      tag: "yaml",
      filename: "doc.yaml",
      file_body: "ok: true",
    },
    {
      label: "case 024 text note",
      boundary: "case024",
      title: "text note",
      tag: "note",
      filename: "note.txt",
      file_body: "note body",
    },
    {
      label: "case 025 binary label",
      boundary: "case025",
      title: "binary label",
      tag: "binary",
      filename: "binary.bin",
      file_body: "010101",
    },
    {
      label: "case 026 avatar upload",
      boundary: "case026",
      title: "avatar upload",
      tag: "image",
      filename: "avatar.png",
      file_body: "png-data",
    },
    {
      label: "case 027 archive name",
      boundary: "case027",
      title: "archive name",
      tag: "archive",
      filename: "bundle.zip",
      file_body: "zip-data",
    },
    {
      label: "case 028 safe path",
      boundary: "case028",
      title: "safe path",
      tag: "safe",
      filename: "safe.txt",
      file_body: "safe-data",
    },
    {
      label: "case 029 unicode label ascii body",
      boundary: "case029",
      title: "unicode label",
      tag: "ascii",
      filename: "unicode.txt",
      file_body: "ascii-body",
    },
    {
      label: "case 030 hyphen file",
      boundary: "case030",
      title: "hyphen file",
      tag: "hyphen",
      filename: "my-file.txt",
      file_body: "hyphen-body",
    },
    {
      label: "case 031 underscore file",
      boundary: "case031",
      title: "underscore file",
      tag: "underscore",
      filename: "my_file.txt",
      file_body: "underscore-body",
    },
    {
      label: "case 032 dotted file",
      boundary: "case032",
      title: "dotted file",
      tag: "dotted",
      filename: "my.file.txt",
      file_body: "dotted-body",
    },
    {
      label: "case 033 tiny body",
      boundary: "case033",
      title: "tiny body",
      tag: "tiny",
      filename: "tiny.txt",
      file_body: "x",
    },
    {
      label: "case 034 medium body",
      boundary: "case034",
      title: "medium body",
      tag: "medium",
      filename: "medium.txt",
      file_body: "abcdefghijklmnopqrstuvwxyz",
    },
    {
      label: "case 035 repeated word",
      boundary: "case035",
      title: "repeat repeat",
      tag: "repeat",
      filename: "repeat.txt",
      file_body: "repeat repeat repeat",
    },
    {
      label: "case 036 numbers body",
      boundary: "case036",
      title: "numbers body",
      tag: "numbers",
      filename: "numbers.txt",
      file_body: "0 1 2 3 4 5 6 7 8 9",
    },
    {
      label: "case 037 punctuation body",
      boundary: "case037",
      title: "punctuation body",
      tag: "punct",
      filename: "punct.txt",
      file_body: "!#$&()+,-.",
    },
    {
      label: "case 038 quoted filename",
      boundary: "case038",
      title: "quoted filename",
      tag: "quote",
      filename: "quote.txt",
      file_body: "quote-body",
    },
    {
      label: "case 039 report upload",
      boundary: "case039",
      title: "report upload",
      tag: "report",
      filename: "monthly-report.txt",
      file_body: "monthly report",
    },
    {
      label: "case 040 api fixture",
      boundary: "case040",
      title: "api fixture",
      tag: "fixture",
      filename: "fixture.txt",
      file_body: "fixture body",
    },
    {
      label: "case 041 parser fixture",
      boundary: "case041",
      title: "parser fixture",
      tag: "parser",
      filename: "parser.txt",
      file_body: "parser body",
    },
    {
      label: "case 042 encoder fixture",
      boundary: "case042",
      title: "encoder fixture",
      tag: "encoder",
      filename: "encoder.txt",
      file_body: "encoder body",
    },
    {
      label: "case 043 validator fixture",
      boundary: "case043",
      title: "validator fixture",
      tag: "validator",
      filename: "validator.txt",
      file_body: "validator body",
    },
    {
      label: "case 044 security fixture",
      boundary: "case044",
      title: "security fixture",
      tag: "security",
      filename: "security.txt",
      file_body: "security body",
    },
    {
      label: "case 045 ci fixture",
      boundary: "case045",
      title: "ci fixture",
      tag: "ci",
      filename: "ci.txt",
      file_body: "ci body",
    },
    {
      label: "case 046 docs fixture",
      boundary: "case046",
      title: "docs fixture",
      tag: "docs",
      filename: "docs.txt",
      file_body: "docs body",
    },
    {
      label: "case 047 example fixture",
      boundary: "case047",
      title: "example fixture",
      tag: "example",
      filename: "example.txt",
      file_body: "example body",
    },
    {
      label: "case 048 package fixture",
      boundary: "case048",
      title: "package fixture",
      tag: "package",
      filename: "package.txt",
      file_body: "package body",
    },
    {
      label: "case 049 upload alpha",
      boundary: "case049",
      title: "upload alpha",
      tag: "alpha",
      filename: "alpha.txt",
      file_body: "alpha body",
    },
    {
      label: "case 050 upload beta",
      boundary: "case050",
      title: "upload beta",
      tag: "beta",
      filename: "beta.txt",
      file_body: "beta body",
    },
    {
      label: "case 051 upload gamma",
      boundary: "case051",
      title: "upload gamma",
      tag: "gamma",
      filename: "gamma.txt",
      file_body: "gamma body",
    },
    {
      label: "case 052 upload delta",
      boundary: "case052",
      title: "upload delta",
      tag: "delta",
      filename: "delta.txt",
      file_body: "delta body",
    },
    {
      label: "case 053 upload epsilon",
      boundary: "case053",
      title: "upload epsilon",
      tag: "epsilon",
      filename: "epsilon.txt",
      file_body: "epsilon body",
    },
    {
      label: "case 054 upload zeta",
      boundary: "case054",
      title: "upload zeta",
      tag: "zeta",
      filename: "zeta.txt",
      file_body: "zeta body",
    },
    {
      label: "case 055 upload eta",
      boundary: "case055",
      title: "upload eta",
      tag: "eta",
      filename: "eta.txt",
      file_body: "eta body",
    },
    {
      label: "case 056 upload theta",
      boundary: "case056",
      title: "upload theta",
      tag: "theta",
      filename: "theta.txt",
      file_body: "theta body",
    },
    {
      label: "case 057 upload iota",
      boundary: "case057",
      title: "upload iota",
      tag: "iota",
      filename: "iota.txt",
      file_body: "iota body",
    },
    {
      label: "case 058 upload kappa",
      boundary: "case058",
      title: "upload kappa",
      tag: "kappa",
      filename: "kappa.txt",
      file_body: "kappa body",
    },
    {
      label: "case 059 upload lambda",
      boundary: "case059",
      title: "upload lambda",
      tag: "lambda",
      filename: "lambda.txt",
      file_body: "lambda body",
    },
    {
      label: "case 060 upload mu",
      boundary: "case060",
      title: "upload mu",
      tag: "mu",
      filename: "mu.txt",
      file_body: "mu body",
    },
    {
      label: "case 061 upload nu",
      boundary: "case061",
      title: "upload nu",
      tag: "nu",
      filename: "nu.txt",
      file_body: "nu body",
    },
    {
      label: "case 062 upload xi",
      boundary: "case062",
      title: "upload xi",
      tag: "xi",
      filename: "xi.txt",
      file_body: "xi body",
    },
    {
      label: "case 063 upload omicron",
      boundary: "case063",
      title: "upload omicron",
      tag: "omicron",
      filename: "omicron.txt",
      file_body: "omicron body",
    },
    {
      label: "case 064 upload pi",
      boundary: "case064",
      title: "upload pi",
      tag: "pi",
      filename: "pi.txt",
      file_body: "pi body",
    },
    {
      label: "case 065 upload rho",
      boundary: "case065",
      title: "upload rho",
      tag: "rho",
      filename: "rho.txt",
      file_body: "rho body",
    },
    {
      label: "case 066 upload sigma",
      boundary: "case066",
      title: "upload sigma",
      tag: "sigma",
      filename: "sigma.txt",
      file_body: "sigma body",
    },
    {
      label: "case 067 upload tau",
      boundary: "case067",
      title: "upload tau",
      tag: "tau",
      filename: "tau.txt",
      file_body: "tau body",
    },
    {
      label: "case 068 upload upsilon",
      boundary: "case068",
      title: "upload upsilon",
      tag: "upsilon",
      filename: "upsilon.txt",
      file_body: "upsilon body",
    },
    {
      label: "case 069 upload phi",
      boundary: "case069",
      title: "upload phi",
      tag: "phi",
      filename: "phi.txt",
      file_body: "phi body",
    },
    {
      label: "case 070 upload chi",
      boundary: "case070",
      title: "upload chi",
      tag: "chi",
      filename: "chi.txt",
      file_body: "chi body",
    },
    {
      label: "case 071 upload psi",
      boundary: "case071",
      title: "upload psi",
      tag: "psi",
      filename: "psi.txt",
      file_body: "psi body",
    },
    {
      label: "case 072 upload omega",
      boundary: "case072",
      title: "upload omega",
      tag: "omega",
      filename: "omega.txt",
      file_body: "omega body",
    },
    {
      label: "case 073 issue attachment",
      boundary: "case073",
      title: "issue attachment",
      tag: "issue",
      filename: "issue.txt",
      file_body: "issue body",
    },
    {
      label: "case 074 pull request attachment",
      boundary: "case074",
      title: "pull request attachment",
      tag: "pull-request",
      filename: "pull-request.txt",
      file_body: "pull request body",
    },
    {
      label: "case 075 release asset",
      boundary: "case075",
      title: "release asset",
      tag: "release",
      filename: "release.txt",
      file_body: "release body",
    },
    {
      label: "case 076 backup upload",
      boundary: "case076",
      title: "backup upload",
      tag: "backup",
      filename: "backup.txt",
      file_body: "backup body",
    },
    {
      label: "case 077 import upload",
      boundary: "case077",
      title: "import upload",
      tag: "import",
      filename: "import.txt",
      file_body: "import body",
    },
    {
      label: "case 078 export upload",
      boundary: "case078",
      title: "export upload",
      tag: "export",
      filename: "export.txt",
      file_body: "export body",
    },
    {
      label: "case 079 dataset upload",
      boundary: "case079",
      title: "dataset upload",
      tag: "dataset",
      filename: "dataset.txt",
      file_body: "dataset body",
    },
    {
      label: "case 080 model upload",
      boundary: "case080",
      title: "model upload",
      tag: "model",
      filename: "model.txt",
      file_body: "model body",
    },
    {
      label: "case 081 artifact upload",
      boundary: "case081",
      title: "artifact upload",
      tag: "artifact",
      filename: "artifact.txt",
      file_body: "artifact body",
    },
    {
      label: "case 082 snapshot upload",
      boundary: "case082",
      title: "snapshot upload",
      tag: "snapshot",
      filename: "snapshot.txt",
      file_body: "snapshot body",
    },
    {
      label: "case 083 migration upload",
      boundary: "case083",
      title: "migration upload",
      tag: "migration",
      filename: "migration.txt",
      file_body: "migration body",
    },
    {
      label: "case 084 final acceptance upload",
      boundary: "case084",
      title: "final acceptance upload",
      tag: "acceptance",
      filename: "acceptance.txt",
      file_body: "acceptance body",
    },
  ]
}

///|
pub fn regression_fixtures() -> Array[MultipartFixture] {
  let fixtures = Array::new()
  let specs = regression_specs()
  let mut i = 0
  while i < specs.length() {
    fixtures.push(regression_fixture_from_spec(specs[i]))
    i = i + 1
  }
  fixtures
}

///|
pub fn regression_fixture_count() -> Int {
  regression_specs().length()
}

///|
pub fn regression_fixture_names() -> Array[String] {
  let names = Array::new()
  let fixtures = regression_fixtures()
  let mut i = 0
  while i < fixtures.length() {
    names.push(fixtures[i].name)
    i = i + 1
  }
  names
}
