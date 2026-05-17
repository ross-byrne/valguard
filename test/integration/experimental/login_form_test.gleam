//// Integration test mirroring login_form_test.gleam against the experimental
//// parse + validate pipeline.

import gleam/dynamic
import gleam/result
import integration/experimental/shared/fixtures
import valguard.{type ValidationError, ValidationError}
import valguard/experimental as ve
import valguard/experimental/validate as ev

// ================== Test setup ===================

type LoginParams {
  LoginParams(email: String, password: String)
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

fn login_schema() -> ve.Schema(LoginParams) {
  let required = "This field is required"
  use email <- ve.string_field("email", required, [
    ev.email_is_valid("Email address is not valid"),
  ])
  use password <- ve.string_field("password", required, [])
  ve.success(LoginParams(email, password))
}

fn validate_params(data: dynamic.Dynamic) -> Result(LoginParams, Errors) {
  ve.parse(login_schema(), data, [])
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
  // HTML forms submit empty values as "". string_field's required_message
  // catches both missing keys and empty values.
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

// ================== Native form-data via parse_form ===================

pub fn parse_form_login_validates_successfully_test() {
  let form_values = [
    #("email", "testing@test.com"),
    #("password", "qwerty"),
  ]

  let actual =
    ve.parse_form(login_schema(), form_values, [])
    |> result.map_error(ErrorValidatingParams)

  assert actual
    == Ok(LoginParams(email: "testing@test.com", password: "qwerty"))
}

pub fn parse_form_login_returns_validation_errors_test() {
  let form_values = [#("email", "not an email"), #("password", "")]

  let actual =
    ve.parse_form(login_schema(), form_values, [])
    |> result.map_error(ErrorValidatingParams)

  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
        ValidationError(key: "password", value: "This field is required"),
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
// the required check) AND password is too short (fails string_min) — both
// errors must come back in the same list, in declaration order.
pub fn login_form_chain_does_not_short_circuit_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("")),
      #(dynamic.string("password"), dynamic.string("qw")),
    ])

  let schema = {
    use email <- ve.string_field("email", "This field is required", [])
    use password <- ve.string_field("password", "Password is required", [
      ev.string_min(8, "Password must be at least 8 characters"),
    ])
    ve.success(LoginParams(email, password))
  }

  let actual =
    ve.parse(schema, data, [])
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
