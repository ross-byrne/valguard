//// Integration test mirroring login_form_test.gleam against the experimental
//// parse + validate pipeline.
////
//// The schema is declared as a function returning a Decoder; ve.parse applies
//// it to a Dynamic payload and returns either the typed record or every
//// accumulated error in one list.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import integration/experimental/shared/fixtures
import valguard.{type ValidationError, ValidationError}
import valguard/experimental as ve
import valguard/validate as v

// ================== Test setup ===================

type LoginParams {
  LoginParams(email: String, password: String)
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

fn login_schema() -> ve.Schema(LoginParams) {
  use email <- ve.field_with("email", decode.string, [
    v.string_required(_, "This field is required"),
    v.email_is_valid(_, "Email address is not valid"),
  ])
  use password <- ve.field_with("password", decode.string, [
    v.string_required(_, "This field is required"),
  ])
  decode.success(LoginParams(email, password))
}

fn validate_params(data: dynamic.Dynamic) -> Result(LoginParams, Errors) {
  ve.parse(login_schema(), data)
  |> result.map_error(ErrorValidatingParams)
}

// ================== Tests ===================

pub fn login_form_validates_successfully_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("testing@test.com")),
      #(dynamic.string("password"), dynamic.string("qwerty")),
    ])

  let result = validate_params(data)
  assert result
    == Ok(LoginParams(email: "testing@test.com", password: "qwerty"))
}

pub fn login_form_is_missing_fields_test() {
  // Real HTML forms always submit keys; empty inputs arrive as "". The schema's
  // string_required predicates handle the "blank" case. (For JSON APIs where
  // a key may be genuinely absent, use optional_field_with with a default.)
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("")),
      #(dynamic.string("password"), dynamic.string("")),
    ])

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "This field is required"),
        ValidationError(key: "password", value: "This field is required"),
      ]),
    )

  assert actual == expected
}

pub fn login_form_has_invalid_email_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("not an email")),
      #(dynamic.string("password"), dynamic.string("qwerty")),
    ])

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
      ]),
    )

  assert actual == expected
}

// ================== End-to-end with a JSON fixture ===================

pub fn json_login_validates_successfully_test() {
  let data = fixtures.load("valid_login.json")

  let actual = validate_params(data)
  assert actual
    == Ok(LoginParams(email: "testing@test.com", password: "qwerty"))
}

pub fn json_login_returns_validation_errors_test() {
  let data = fixtures.load("invalid_login.json")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
        ValidationError(key: "password", value: "This field is required"),
      ]),
    )

  assert actual == expected
}

// ================== Chain accumulation ===================

// Verifies that validations do not short-circuit. Email is empty (fails
// string_required) AND password is too short (fails string_min) — both errors
// must come back in the same list, in declaration order.
pub fn login_form_chain_does_not_short_circuit_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("")),
      #(dynamic.string("password"), dynamic.string("qw")),
    ])

  let schema = {
    use email <- ve.field_with("email", decode.string, [
      v.string_required(_, "This field is required"),
    ])
    use password <- ve.field_with("password", decode.string, [
      v.string_min(_, min: 8, message: "Password must be at least 8 characters"),
    ])
    decode.success(LoginParams(email, password))
  }

  let actual =
    ve.parse(schema, data)
    |> result.map_error(ErrorValidatingParams)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "This field is required"),
        ValidationError(
          key: "password",
          value: "Password must be at least 8 characters",
        ),
      ]),
    )

  assert actual == expected
}
