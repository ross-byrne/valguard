//// Unit tests for valguard/experimental — covering each public function in
//// isolation. Tests use small, focused Dynamic payloads.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/option.{None, Some}
import valguard.{ValidationError}
import valguard/experimental as ve
import valguard/experimental/validate as ev

// ================== parse ===================

pub fn parse_returns_ok_for_trivial_decoder_test() {
  let actual = ve.parse(ve.success(42), dynamic.int(0), [])
  assert actual == Ok(42)
}

pub fn parse_translates_decode_error_path_to_key_test() {
  let data = dynamic.properties([#(dynamic.string("name"), dynamic.int(42))])
  let schema = {
    use name <- decode.field("name", decode.string)
    ve.success(name)
  }

  let actual = ve.parse(schema, data, [])
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
    ve.success(age)
  }

  let actual = ve.parse(schema, data, [])
  let expected = Error([ValidationError(key: "user.age", value: "Int")])
  assert actual == expected
}

// ================== string_field ===================

pub fn string_field_passes_when_value_present_test() {
  let data =
    dynamic.properties([#(dynamic.string("email"), dynamic.string("foo@bar"))])
  let schema = {
    use email <- ve.string_field("email", "Email is required", [])
    ve.success(email)
  }

  assert ve.parse(schema, data, []) == Ok("foo@bar")
}

pub fn string_field_emits_required_message_when_key_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use email <- ve.string_field("email", "Email is required", [])
    ve.success(email)
  }

  let expected =
    Error([ValidationError(key: "email", value: "Email is required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn string_field_rejects_empty_string_using_required_message_test() {
  // Required string fields ALWAYS reject empty input — missing key and
  // empty string both surface the same required_message. To allow empty
  // values, use optional_string_field instead.
  let data = dynamic.properties([#(dynamic.string("name"), dynamic.string(""))])
  let schema = {
    use name <- ve.string_field("name", "Name is required", [])
    ve.success(name)
  }

  let expected =
    Error([ValidationError(key: "name", value: "Name is required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn string_field_runs_predicates_on_non_empty_value_test() {
  let data =
    dynamic.properties([#(dynamic.string("name"), dynamic.string("ab"))])
  let schema = {
    use name <- ve.string_field("name", "Required", [
      ev.string_min(5, "Too short"),
    ])
    ve.success(name)
  }

  let expected = Error([ValidationError(key: "name", value: "Too short")])
  assert ve.parse(schema, data, []) == expected
}

pub fn string_field_emits_required_message_on_wrong_type_test() {
  // JSON-style: number where string expected. Per design, wrong-type → required_message.
  let data = dynamic.properties([#(dynamic.string("name"), dynamic.int(42))])
  let schema = {
    use name <- ve.string_field("name", "Required", [])
    ve.success(name)
  }

  let expected = Error([ValidationError(key: "name", value: "Required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn string_field_short_circuits_predicate_list_test() {
  let data =
    dynamic.properties([#(dynamic.string("name"), dynamic.string("a"))])
  let schema = {
    use name <- ve.string_field("name", "Required", [
      ev.string_min(5, "Too short"),
      ev.string_max(3, "Too long"),
    ])
    ve.success(name)
  }

  // string_min fails first; string_max never runs.
  let expected = Error([ValidationError(key: "name", value: "Too short")])
  assert ve.parse(schema, data, []) == expected
}

pub fn string_field_accumulates_errors_across_fields_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("a"), dynamic.string("")),
      #(dynamic.string("b"), dynamic.string("")),
    ])
  let schema = {
    use a <- ve.string_field("a", "A required", [])
    use b <- ve.string_field("b", "B required", [])
    ve.success(#(a, b))
  }

  let expected =
    Error([
      ValidationError(key: "a", value: "A required"),
      ValidationError(key: "b", value: "B required"),
    ])
  assert ve.parse(schema, data, []) == expected
}

// ================== int_field ===================

pub fn int_field_parses_json_native_int_test() {
  let data = dynamic.properties([#(dynamic.string("age"), dynamic.int(42))])
  let schema = {
    use age <- ve.int_field("age", "Age is required", [])
    ve.success(age)
  }

  assert ve.parse(schema, data, []) == Ok(42)
}

pub fn int_field_parses_form_string_int_test() {
  let data =
    dynamic.properties([#(dynamic.string("age"), dynamic.string("42"))])
  let schema = {
    use age <- ve.int_field("age", "Age is required", [])
    ve.success(age)
  }

  assert ve.parse(schema, data, []) == Ok(42)
}

pub fn int_field_emits_required_message_when_unparseable_test() {
  let data =
    dynamic.properties([#(dynamic.string("age"), dynamic.string("abc"))])
  let schema = {
    use age <- ve.int_field("age", "Age is required", [])
    ve.success(age)
  }

  let expected = Error([ValidationError(key: "age", value: "Age is required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn int_field_emits_required_message_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use age <- ve.int_field("age", "Age is required", [])
    ve.success(age)
  }

  let expected = Error([ValidationError(key: "age", value: "Age is required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn int_field_runs_predicates_test() {
  let data = dynamic.properties([#(dynamic.string("age"), dynamic.string("0"))])
  let schema = {
    use age <- ve.int_field("age", "Required", [
      ev.int_min(1, "Must be positive"),
    ])
    ve.success(age)
  }

  let expected = Error([ValidationError(key: "age", value: "Must be positive")])
  assert ve.parse(schema, data, []) == expected
}

// ================== float_field ===================

pub fn float_field_parses_form_string_float_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("3.14"))])
  let schema = {
    use price <- ve.float_field("price", "Required", [])
    ve.success(price)
  }

  assert ve.parse(schema, data, []) == Ok(3.14)
}

pub fn float_field_emits_required_on_bad_input_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("free"))])
  let schema = {
    use price <- ve.float_field("price", "Required", [])
    ve.success(price)
  }

  let expected = Error([ValidationError(key: "price", value: "Required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn float_field_parses_json_native_float_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.float(3.14))])
  let schema = {
    use price <- ve.float_field("price", "Required", [])
    ve.success(price)
  }

  assert ve.parse(schema, data, []) == Ok(3.14)
}

pub fn float_field_emits_required_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use price <- ve.float_field("price", "Required", [])
    ve.success(price)
  }

  let expected = Error([ValidationError(key: "price", value: "Required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn float_field_runs_predicates_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("0.5"))])
  let schema = {
    use price <- ve.float_field("price", "Required", [
      ev.float_min(1.0, "Must be at least 1.0"),
    ])
    ve.success(price)
  }

  let expected =
    Error([ValidationError(key: "price", value: "Must be at least 1.0")])
  assert ve.parse(schema, data, []) == expected
}

// ================== bool_field ===================

pub fn bool_field_accepts_string_true_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("true"))])
  let schema = {
    use agreed <- ve.bool_field("agreed", "Required", [])
    ve.success(agreed)
  }

  assert ve.parse(schema, data, []) == Ok(True)
}

pub fn bool_field_accepts_native_bool_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.bool(False))])
  let schema = {
    use agreed <- ve.bool_field("agreed", "Required", [])
    ve.success(agreed)
  }

  assert ve.parse(schema, data, []) == Ok(False)
}

pub fn bool_field_rejects_unknown_string_with_required_message_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("maybe"))])
  let schema = {
    use agreed <- ve.bool_field("agreed", "Must agree", [])
    ve.success(agreed)
  }

  let expected = Error([ValidationError(key: "agreed", value: "Must agree")])
  assert ve.parse(schema, data, []) == expected
}

pub fn bool_field_runs_bool_true_predicate_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("false"))])
  let schema = {
    use agreed <- ve.bool_field("agreed", "Required", [
      ev.bool_true("You must agree"),
    ])
    ve.success(agreed)
  }

  let expected =
    Error([ValidationError(key: "agreed", value: "You must agree")])
  assert ve.parse(schema, data, []) == expected
}

// ================== optional_string_field ===================

pub fn optional_string_field_returns_none_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use bio <- ve.optional_string_field("bio", [])
    ve.success(bio)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_string_field_returns_none_when_empty_test() {
  let data = dynamic.properties([#(dynamic.string("bio"), dynamic.string(""))])
  let schema = {
    use bio <- ve.optional_string_field("bio", [])
    ve.success(bio)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_string_field_returns_some_when_present_test() {
  let data =
    dynamic.properties([#(dynamic.string("bio"), dynamic.string("hello"))])
  let schema = {
    use bio <- ve.optional_string_field("bio", [])
    ve.success(bio)
  }

  assert ve.parse(schema, data, []) == Ok(Some("hello"))
}

pub fn optional_string_field_runs_predicates_on_some_test() {
  let data =
    dynamic.properties([#(dynamic.string("bio"), dynamic.string("hi"))])
  let schema = {
    use bio <- ve.optional_string_field("bio", [
      ev.string_min(3, "Too short"),
    ])
    ve.success(bio)
  }

  let expected = Error([ValidationError(key: "bio", value: "Too short")])
  assert ve.parse(schema, data, []) == expected
}

pub fn optional_string_field_skips_predicates_on_none_test() {
  let data = dynamic.properties([#(dynamic.string("bio"), dynamic.string(""))])
  let schema = {
    use bio <- ve.optional_string_field("bio", [
      ev.string_min(3, "Too short"),
    ])
    ve.success(bio)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_string_field_emits_type_error_on_non_string_test() {
  let data = dynamic.properties([#(dynamic.string("bio"), dynamic.int(42))])
  let schema = {
    use bio <- ve.optional_string_field("bio", [])
    ve.success(bio)
  }

  let expected = Error([ValidationError(key: "bio", value: "Must be a string")])
  assert ve.parse(schema, data, []) == expected
}

// ================== optional_int_field ===================

pub fn optional_int_field_returns_none_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use age <- ve.optional_int_field("age", [])
    ve.success(age)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_int_field_returns_none_on_empty_string_test() {
  let data = dynamic.properties([#(dynamic.string("age"), dynamic.string(""))])
  let schema = {
    use age <- ve.optional_int_field("age", [])
    ve.success(age)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_int_field_returns_some_for_valid_int_test() {
  let data =
    dynamic.properties([#(dynamic.string("age"), dynamic.string("42"))])
  let schema = {
    use age <- ve.optional_int_field("age", [])
    ve.success(age)
  }

  assert ve.parse(schema, data, []) == Ok(Some(42))
}

pub fn optional_int_field_emits_type_error_for_non_empty_garbage_test() {
  let data =
    dynamic.properties([#(dynamic.string("age"), dynamic.string("abc"))])
  let schema = {
    use age <- ve.optional_int_field("age", [])
    ve.success(age)
  }

  let expected =
    Error([ValidationError(key: "age", value: "Must be a valid integer")])
  assert ve.parse(schema, data, []) == expected
}

// ================== optional_float_field ===================

pub fn optional_float_field_returns_none_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use price <- ve.optional_float_field("price", [])
    ve.success(price)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_float_field_returns_none_on_empty_string_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string(""))])
  let schema = {
    use price <- ve.optional_float_field("price", [])
    ve.success(price)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_float_field_returns_some_for_valid_float_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("3.14"))])
  let schema = {
    use price <- ve.optional_float_field("price", [])
    ve.success(price)
  }

  assert ve.parse(schema, data, []) == Ok(Some(3.14))
}

pub fn optional_float_field_runs_predicates_on_some_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("0.5"))])
  let schema = {
    use price <- ve.optional_float_field("price", [
      ev.float_min(1.0, "Must be at least 1.0"),
    ])
    ve.success(price)
  }

  let expected =
    Error([ValidationError(key: "price", value: "Must be at least 1.0")])
  assert ve.parse(schema, data, []) == expected
}

pub fn optional_float_field_type_error_test() {
  let data =
    dynamic.properties([#(dynamic.string("price"), dynamic.string("free"))])
  let schema = {
    use price <- ve.optional_float_field("price", [])
    ve.success(price)
  }

  let expected =
    Error([ValidationError(key: "price", value: "Must be a valid number")])
  assert ve.parse(schema, data, []) == expected
}

// ================== optional_bool_field ===================

pub fn optional_bool_field_returns_none_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use agreed <- ve.optional_bool_field("agreed", [])
    ve.success(agreed)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_bool_field_returns_none_on_empty_string_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string(""))])
  let schema = {
    use agreed <- ve.optional_bool_field("agreed", [])
    ve.success(agreed)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_bool_field_runs_predicates_on_some_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("false"))])
  let schema = {
    use agreed <- ve.optional_bool_field("agreed", [
      ev.bool_true("You must agree"),
    ])
    ve.success(agreed)
  }

  let expected =
    Error([ValidationError(key: "agreed", value: "You must agree")])
  assert ve.parse(schema, data, []) == expected
}

pub fn optional_bool_field_type_error_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("maybe"))])
  let schema = {
    use agreed <- ve.optional_bool_field("agreed", [])
    ve.success(agreed)
  }

  let expected =
    Error([ValidationError(key: "agreed", value: "Must be true or false")])
  assert ve.parse(schema, data, []) == expected
}

pub fn optional_bool_field_some_when_present_test() {
  let data =
    dynamic.properties([#(dynamic.string("agreed"), dynamic.string("true"))])
  let schema = {
    use agreed <- ve.optional_bool_field("agreed", [])
    ve.success(agreed)
  }

  assert ve.parse(schema, data, []) == Ok(Some(True))
}

// ================== field_with (generic escape hatch) ===================

pub fn field_with_uses_placeholder_on_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use s <- ve.field_with("s", decode.string, "placeholder", "Required", [])
    ve.success(s)
  }

  let expected = Error([ValidationError(key: "s", value: "Required")])
  assert ve.parse(schema, data, []) == expected
}

pub fn field_with_succeeds_with_real_value_test() {
  let data = dynamic.properties([#(dynamic.string("s"), dynamic.string("ok"))])
  let schema = {
    use s <- ve.field_with("s", decode.string, "placeholder", "Required", [])
    ve.success(s)
  }

  assert ve.parse(schema, data, []) == Ok("ok")
}

pub fn field_with_placeholder_never_leaks_test() {
  // The placeholder value should NEVER surface in the result.
  let data = dynamic.properties([])
  let schema = {
    use s <- ve.field_with(
      "s",
      decode.string,
      "PLACEHOLDER_DO_NOT_RETURN",
      "Required",
      [],
    )
    ve.success(s)
  }

  let actual = ve.parse(schema, data, [])
  assert actual == Error([ValidationError(key: "s", value: "Required")])
}

// ================== optional_field_with ===================

pub fn optional_field_with_returns_none_when_missing_test() {
  let data = dynamic.properties([])
  let schema = {
    use s <- ve.optional_field_with("s", decode.string, [])
    ve.success(s)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_field_with_returns_some_when_present_test() {
  let data = dynamic.properties([#(dynamic.string("s"), dynamic.string("ok"))])
  let schema = {
    use s <- ve.optional_field_with("s", decode.string, [])
    ve.success(s)
  }

  assert ve.parse(schema, data, []) == Ok(Some("ok"))
}

pub fn optional_field_with_returns_none_on_empty_string_test() {
  let data = dynamic.properties([#(dynamic.string("s"), dynamic.string(""))])
  let schema = {
    use s <- ve.optional_field_with("s", decode.string, [])
    ve.success(s)
  }

  assert ve.parse(schema, data, []) == Ok(None)
}

pub fn optional_field_with_emits_invalid_value_on_type_error_test() {
  let data = dynamic.properties([#(dynamic.string("age"), dynamic.int(42))])
  let schema = {
    use age <- ve.optional_field_with("age", decode.string, [])
    ve.success(age)
  }

  let expected = Error([ValidationError(key: "age", value: "Invalid value")])
  assert ve.parse(schema, data, []) == expected
}

// ================== parse_form ===================

pub fn parse_form_builds_typed_record_test() {
  let values = [#("email", "user@example.com"), #("password", "qwerty")]
  let schema = {
    use email <- ve.string_field("email", "Required", [])
    use password <- ve.string_field("password", "Required", [])
    ve.success(#(email, password))
  }

  assert ve.parse_form(schema, values, [])
    == Ok(#("user@example.com", "qwerty"))
}

pub fn parse_form_accumulates_errors_test() {
  let values = [#("a", ""), #("b", "")]
  let schema = {
    use a <- ve.string_field("a", "A empty", [])
    use b <- ve.string_field("b", "B empty", [])
    ve.success(#(a, b))
  }

  let expected =
    Error([
      ValidationError(key: "a", value: "A empty"),
      ValidationError(key: "b", value: "B empty"),
    ])
  assert ve.parse_form(schema, values, []) == expected
}

pub fn parse_form_supports_int_field_test() {
  let values = [#("age", "42")]
  let schema = {
    use age <- ve.int_field("age", "Required", [])
    ve.success(age)
  }

  assert ve.parse_form(schema, values, []) == Ok(42)
}

// ================== ve.validate ===================

pub fn validate_runs_when_per_field_passes_test() {
  let values = [#("password", "secret123"), #("confirm", "different")]
  let schema = {
    use password <- ve.string_field("password", "Required", [])
    use confirm <- ve.string_field("confirm", "Required", [])
    ve.success(#(password, confirm))
  }

  let actual =
    ve.parse_form(schema, values, [
      ve.validate("confirm", fn(pair: #(String, String)) {
        let #(pw, conf) = pair
        case pw == conf {
          True -> Ok(Nil)
          False -> Error("Passwords must match")
        }
      }),
    ])

  let expected =
    Error([ValidationError(key: "confirm", value: "Passwords must match")])
  assert actual == expected
}

pub fn validate_skipped_when_per_field_fails_test() {
  // Per-field error on "password" (empty); cross-field never runs because
  // phase 1 didn't succeed. The output contains only the per-field error,
  // not a misleading cross-field result against placeholder values.
  let values = [#("password", ""), #("confirm", "different")]
  let schema = {
    use password <- ve.string_field("password", "Password required", [])
    use confirm <- ve.string_field("confirm", "Confirm required", [])
    ve.success(#(password, confirm))
  }

  let actual =
    ve.parse_form(schema, values, [
      ve.validate("confirm", fn(pair: #(String, String)) {
        let #(pw, conf) = pair
        case pw == conf {
          True -> Ok(Nil)
          False -> Error("Passwords must match")
        }
      }),
    ])

  let expected =
    Error([ValidationError(key: "password", value: "Password required")])
  assert actual == expected
}

pub fn validate_passes_when_check_succeeds_test() {
  let values = [#("password", "same"), #("confirm", "same")]
  let schema = {
    use password <- ve.string_field("password", "Required", [])
    use confirm <- ve.string_field("confirm", "Required", [])
    ve.success(#(password, confirm))
  }

  let actual =
    ve.parse_form(schema, values, [
      ve.validate("confirm", fn(pair: #(String, String)) {
        let #(pw, conf) = pair
        case pw == conf {
          True -> Ok(Nil)
          False -> Error("Passwords must match")
        }
      }),
    ])

  assert actual == Ok(#("same", "same"))
}

pub fn validate_accumulates_multiple_checks_test() {
  let values = [#("a", "1"), #("b", "2")]
  let schema = {
    use a <- ve.string_field("a", "Required", [])
    use b <- ve.string_field("b", "Required", [])
    ve.success(#(a, b))
  }

  let actual =
    ve.parse_form(schema, values, [
      ve.validate("a", fn(_) { Error("first cross error") }),
      ve.validate("b", fn(_) { Error("second cross error") }),
    ])

  let expected =
    Error([
      ValidationError(key: "a", value: "first cross error"),
      ValidationError(key: "b", value: "second cross error"),
    ])
  assert actual == expected
}

// ================== check ===================

pub fn check_passes_underlying_value_test() {
  let schema = decode.string |> ve.check(ev.string_not_empty("Required"))

  assert ve.parse(schema, dynamic.string("hello"), []) == Ok("hello")
}

pub fn check_emits_predicate_error_test() {
  let schema = decode.string |> ve.check(ev.string_not_empty("Required"))

  let expected = Error([ValidationError(key: "", value: "Required")])
  assert ve.parse(schema, dynamic.string(""), []) == expected
}
