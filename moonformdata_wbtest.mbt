///|
test "whitebox split header parameters keeps quoted semicolon" {
  debug_inspect(
    split_header_parameters("form-data; name=\"a;b\"; filename=\"x.txt\""),
    content="[\"form-data\", \" name=\\\"a;b\\\"\", \" filename=\\\"x.txt\\\"\"]",
  )
}

///|
test "whitebox parse parameter trims and unquotes" {
  debug_inspect(
    parse_parameter(" boundary = \"abc\""),
    content="Ok((\"boundary\", \"abc\"))",
  )
}

///|
test "whitebox parse parameter rejects invalid token" {
  debug_inspect(parse_parameter("bad name=value"), content="Err(())")
}

///|
test "whitebox boundary validation accepts safe tokens" {
  debug_inspect(validate_boundary("abc-123_+"), content="Ok(\"abc-123_+\")")
}

///|
test "whitebox boundary validation rejects empty and control chars" {
  debug_inspect(validate_boundary(""), content="Err(InvalidBoundary(\"\"))")
  debug_inspect(
    validate_boundary("bad\nboundary"),
    content="Err(InvalidBoundary(\"bad\\nboundary\"))",
  )
}

///|
test "whitebox newline stripping removes only framing newline" {
  debug_inspect(strip_one_leading_newline("\r\nbody"), content="\"body\"")
  debug_inspect(strip_one_trailing_newline("body\r\n"), content="\"body\"")
  debug_inspect(strip_one_trailing_newline("body"), content="\"body\"")
}

///|
test "whitebox quoted value escaping roundtrips" {
  let escaped = escape_quoted("a\"b\\c")
  debug_inspect(escaped, content="\"a\\\\\\\"b\\\\\\\\c\"")
  debug_inspect(unescape_quoted(escaped), content="\"a\\\"b\\\\c\"")
}

///|
test "whitebox header linebreaks are stripped" {
  debug_inspect(strip_header_linebreaks("one\r\ntwo"), content="\"onetwo\"")
}

///|
test "whitebox token helper matches header grammar" {
  debug_inspect(is_token("Content-Type"), content="true")
  debug_inspect(is_token("Bad Header"), content="false")
  debug_inspect(is_safe_header_name("X-Trace-Id"), content="true")
}

///|
test "whitebox parse headers rejects unsafe names" {
  debug_inspect(
    parse_headers("Good: 1\r\nBad Header: 2", 8),
    content="Err(InvalidHeader(\"Bad Header: 2\"))",
  )
}

///|
test "whitebox display snippet escapes control characters" {
  debug_inspect(
    display_snippet("a\r\nb\\c"),
    content="\"a\\\\r\\\\nb\\\\\\\\c\"",
  )
}

///|
test "whitebox percent decoder accepts uppercase and lowercase hex" {
  debug_inspect(decode_percent_ascii("a%20b%2ec"), content="Ok(\"a b.c\")")
}
