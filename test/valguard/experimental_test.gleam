//// Unit tests for valguard/experimental — covering each public function in
//// isolation. Tests use small, focused Dynamic payloads.

import gleam/dynamic
import gleam/dynamic/decode
import valguard.{ValidationError}
import valguard/experimental as ve
import valguard/validate as v

// ================== parse ===================

pub fn parse_returns_ok_for_trivial_decoder_test() {
  let actual = ve.parse(decode.success(42), dynamic.int(0))
  let expected = Ok(42)
  assert actual == expected
}

pub fn parse_translates_decode_error_path_to_key_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.int(42)),
    ])
  let schema = {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  }

  let actual = ve.parse(schema, data)
  // Underlying decode reports expected="String", path=["name"].
  let expected = Error([ValidationError(key: "name", value: "String")])
  assert actual == expected
}

pub fn parse_joins_nested_path_with_dots_test() {
  let data =
    dynamic.properties([
      #(
        dynamic.string("user"),
        dynamic.properties([
          #(dynamic.string("age"), dynamic.string("not a number")),
        ]),
      ),
    ])
  let schema = {
    use age <- decode.subfield(["user", "age"], decode.int)
    decode.success(age)
  }

  let actual = ve.parse(schema, data)
  let expected = Error([ValidationError(key: "user.age", value: "Int")])
  assert actual == expected
}

// ================== field_with ===================

pub fn field_with_passes_when_all_predicates_succeed_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("user@example.com")),
    ])
  let schema = {
    use email <- ve.field_with("email", decode.string, [
      v.string_required(_, "Required"),
      v.email_is_valid(_, "Invalid email"),
    ])
    decode.success(email)
  }

  let actual = ve.parse(schema, data)
  assert actual == Ok("user@example.com")
}

pub fn field_with_returns_predicate_error_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("not-an-email")),
    ])
  let schema = {
    use email <- ve.field_with("email", decode.string, [
      v.email_is_valid(_, "Invalid email"),
    ])
    decode.success(email)
  }

  let actual = ve.parse(schema, data)
  let expected = Error([ValidationError(key: "email", value: "Invalid email")])
  assert actual == expected
}

pub fn field_with_short_circuits_predicate_list_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("")),
    ])
  let schema = {
    use name <- ve.field_with("name", decode.string, [
      v.string_required(_, "Required"),
      v.string_min(_, min: 5, message: "Too short"),
    ])
    decode.success(name)
  }

  let actual = ve.parse(schema, data)
  // string_required fires first; string_min never runs.
  let expected = Error([ValidationError(key: "name", value: "Required")])
  assert actual == expected
}

pub fn field_with_reports_required_when_field_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use name <- ve.field_with("name", decode.string, [
      v.string_required(_, "Required"),
    ])
    decode.success(name)
  }

  let actual = ve.parse(schema, data)
  // Missing key surfaces as the friendly "Field is required" message;
  // predicates do not run on the placeholder.
  let expected =
    Error([ValidationError(key: "name", value: "Field is required")])
  assert actual == expected
}

pub fn field_with_returns_type_error_when_wrong_type_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.int(42)),
    ])
  let schema = {
    use name <- ve.field_with("name", decode.string, [
      v.string_required(_, "Required"),
    ])
    decode.success(name)
  }

  let actual = ve.parse(schema, data)
  // Type mismatch surfaces; predicates do not run on the placeholder.
  let expected = Error([ValidationError(key: "name", value: "String")])
  assert actual == expected
}

pub fn field_with_accumulates_errors_across_fields_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("name"), dynamic.string("")),
      #(dynamic.string("email"), dynamic.string("bad")),
    ])
  let schema = {
    use name <- ve.field_with("name", decode.string, [
      v.string_required(_, "Required"),
    ])
    use email <- ve.field_with("email", decode.string, [
      v.email_is_valid(_, "Invalid email"),
    ])
    decode.success(#(name, email))
  }

  let actual = ve.parse(schema, data)
  let expected =
    Error([
      ValidationError(key: "name", value: "Required"),
      ValidationError(key: "email", value: "Invalid email"),
    ])
  assert actual == expected
}

// ================== optional_field_with ===================

pub fn optional_field_with_uses_default_when_field_absent_test() {
  let data = dynamic.properties([])
  let schema = {
    use bio <- ve.optional_field_with("bio", "", decode.string, [
      v.string_min(_, min: 1, message: "Must not be empty"),
    ])
    decode.success(bio)
  }

  let actual = ve.parse(schema, data)
  // Default is used; predicates do NOT run against the default.
  assert actual == Ok("")
}

pub fn optional_field_with_runs_predicates_when_field_present_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("bio"), dynamic.string("hello")),
    ])
  let schema = {
    use bio <- ve.optional_field_with("bio", "", decode.string, [
      v.string_min(_, min: 3, message: "Too short"),
    ])
    decode.success(bio)
  }

  let actual = ve.parse(schema, data)
  assert actual == Ok("hello")
}

pub fn optional_field_with_surfaces_predicate_error_when_present_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("bio"), dynamic.string("hi")),
    ])
  let schema = {
    use bio <- ve.optional_field_with("bio", "", decode.string, [
      v.string_min(_, min: 3, message: "Too short"),
    ])
    decode.success(bio)
  }

  let actual = ve.parse(schema, data)
  let expected = Error([ValidationError(key: "bio", value: "Too short")])
  assert actual == expected
}

pub fn optional_field_with_surfaces_type_error_when_wrong_type_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("count"), dynamic.string("not a number")),
    ])
  let schema = {
    use count <- ve.optional_field_with("count", 0, decode.int, [
      v.int_min(_, min: 1, message: "Must be at least 1"),
    ])
    decode.success(count)
  }

  let actual = ve.parse(schema, data)
  // Key is present but type is wrong; the inner decoder's type error surfaces
  // and predicates do not run on the placeholder.
  let expected = Error([ValidationError(key: "count", value: "Int")])
  assert actual == expected
}

// ================== check ===================

pub fn check_passes_underlying_value_test() {
  let schema = decode.string |> ve.check(v.string_required(_, "Required"))

  let actual = ve.parse(schema, dynamic.string("hello"))
  assert actual == Ok("hello")
}

pub fn check_emits_predicate_error_test() {
  let schema = decode.string |> ve.check(v.string_required(_, "Required"))

  let actual = ve.parse(schema, dynamic.string(""))
  // No path because check runs at the root; key is empty.
  let expected = Error([ValidationError(key: "", value: "Required")])
  assert actual == expected
}

pub fn check_surfaces_decoder_error_without_running_predicate_test() {
  let schema = decode.string |> ve.check(v.string_required(_, "Required"))

  let actual = ve.parse(schema, dynamic.int(42))
  // Underlying decoder fails on the wrong type; the predicate would have ALSO
  // failed against the placeholder, but its error is suppressed so only the
  // type error surfaces.
  let expected = Error([ValidationError(key: "", value: "String")])
  assert actual == expected
}

// ================== success_with ===================

pub fn success_with_returns_value_when_all_checks_pass_test() {
  let schema =
    ve.success_with(#("foo", "foo"), [
      fn(pair: #(String, String)) {
        let #(a, b) = pair
        case a == b {
          True -> Ok(Nil)
          False -> Error(ValidationError("mismatch", "values must match"))
        }
      },
    ])

  let actual = ve.parse(schema, dynamic.nil())
  assert actual == Ok(#("foo", "foo"))
}

pub fn success_with_emits_single_check_error_test() {
  let schema =
    ve.success_with(#("foo", "bar"), [
      fn(pair: #(String, String)) {
        let #(a, b) = pair
        case a == b {
          True -> Ok(Nil)
          False -> Error(ValidationError("mismatch", "values must match"))
        }
      },
    ])

  let actual = ve.parse(schema, dynamic.nil())
  let expected =
    Error([ValidationError(key: "mismatch", value: "values must match")])
  assert actual == expected
}

pub fn success_with_accumulates_multiple_check_errors_test() {
  let schema =
    ve.success_with("anything", [
      fn(_) { Error(ValidationError("a", "first")) },
      fn(_) { Error(ValidationError("b", "second")) },
      fn(_) { Ok(Nil) },
      fn(_) { Error(ValidationError("c", "third")) },
    ])

  let actual = ve.parse(schema, dynamic.nil())
  let expected =
    Error([
      ValidationError(key: "a", value: "first"),
      ValidationError(key: "b", value: "second"),
      ValidationError(key: "c", value: "third"),
    ])
  assert actual == expected
}

// ================== success_with composed inside a schema ===================

pub fn success_with_composes_with_field_with_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("abc")),
      #(dynamic.string("confirm"), dynamic.string("xyz")),
    ])
  let schema = {
    use password <- ve.field_with("password", decode.string, [])
    use confirm <- ve.field_with("confirm", decode.string, [])
    ve.success_with(#(password, confirm), [
      fn(pair: #(String, String)) {
        let #(a, b) = pair
        case a == b {
          True -> Ok(Nil)
          False -> Error(ValidationError("confirm", "passwords must match"))
        }
      },
    ])
  }

  let actual = ve.parse(schema, data)
  let expected =
    Error([ValidationError(key: "confirm", value: "passwords must match")])
  assert actual == expected
}
