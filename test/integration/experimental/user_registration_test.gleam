//// Integration test mirroring user_registeration_test.gleam against the
//// experimental parse + validate pipeline. Demonstrates per-field validation
//// plus cross-field validation (passwords_match) in a single ve.parse call.

import gleam/dynamic
import gleam/result
import integration/experimental/shared/fixtures
import valguard.{type ValidationError, ValidationError}
import valguard/experimental as ve
import valguard/experimental/validate as ev

// ================== Test setup ===================

type RegisterParams {
  RegisterParams(
    first_name: String,
    last_name: String,
    email: String,
    password: String,
    confirm_password: String,
  )
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

fn register_schema() -> ve.Schema(RegisterParams) {
  let required = "This field is required"
  use first_name <- ve.string_field("first_name", required, [])
  use last_name <- ve.string_field("last_name", required, [])
  use email <- ve.string_field("email", required, [
    ev.email_is_valid("Email address is not valid"),
  ])
  use password <- ve.string_field("password", required, [
    ev.string_min(8, "Password must be a minimum of 8 characters"),
  ])
  use confirm_password <- ve.string_field("confirm_password", required, [])
  ve.success(RegisterParams(
    first_name,
    last_name,
    email,
    password,
    confirm_password,
  ))
}

/// Cross-field check: password and confirm_password must match.
fn passwords_must_match(p: RegisterParams) -> Result(Nil, String) {
  case p.password == p.confirm_password {
    True -> Ok(Nil)
    False -> Error("Password & Confirm Password must match")
  }
}

fn validate_params(data: dynamic.Dynamic) -> Result(RegisterParams, Errors) {
  ve.parse(register_schema(), data, [
    ve.cross("confirm_password", passwords_must_match),
  ])
  |> result.map_error(ErrorValidatingParams)
}

fn payload(
  first_name: String,
  last_name: String,
  email: String,
  password: String,
  confirm_password: String,
) -> dynamic.Dynamic {
  dynamic.properties([
    #(dynamic.string("first_name"), dynamic.string(first_name)),
    #(dynamic.string("last_name"), dynamic.string(last_name)),
    #(dynamic.string("email"), dynamic.string(email)),
    #(dynamic.string("password"), dynamic.string(password)),
    #(dynamic.string("confirm_password"), dynamic.string(confirm_password)),
  ])
}

// ================== Tests ===================

pub fn register_form_validates_successfully_test() {
  let data =
    payload("Jim", "Bean", "testing@test.com", "qwerty123", "qwerty123")

  let result = validate_params(data)
  assert result
    == Ok(RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "testing@test.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    ))
}

pub fn register_form_is_missing_fields_test() {
  let data = payload("", "", "", "", "")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "first_name", value: "This field is required"),
        ValidationError(key: "last_name", value: "This field is required"),
        ValidationError(key: "email", value: "This field is required"),
        ValidationError(key: "password", value: "This field is required"),
        ValidationError(
          key: "confirm_password",
          value: "This field is required",
        ),
      ]),
    )

  assert actual == expected
}

pub fn register_form_password_is_too_short_test() {
  let data = payload("Jim", "Bean", "test@test.com", "qwe", "qwe")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(
          key: "password",
          value: "Password must be a minimum of 8 characters",
        ),
      ]),
    )

  assert actual == expected
}

pub fn register_form_passwords_dont_match_test() {
  let data = payload("Jim", "Bean", "test@test.com", "qwerty123", "asdfgh1235")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(
          key: "confirm_password",
          value: "Password & Confirm Password must match",
        ),
      ]),
    )

  assert actual == expected
}

// Cross-field is gated on per-field success: when first_name and password
// are empty, those per-field errors come back AND the cross-field check
// (passwords_must_match) does NOT run against placeholder values.
pub fn register_form_cross_field_gated_on_per_field_success_test() {
  let data = payload("", "", "", "", "")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "first_name", value: "This field is required"),
        ValidationError(key: "last_name", value: "This field is required"),
        ValidationError(key: "email", value: "This field is required"),
        ValidationError(key: "password", value: "This field is required"),
        ValidationError(
          key: "confirm_password",
          value: "This field is required",
        ),
      ]),
    )

  // No "Password & Confirm Password must match" error — the cross-field
  // check is skipped when per-field validation fails.
  assert actual == expected
}

// ================== Native form-data via parse_form ===================

fn form_payload(
  first_name: String,
  last_name: String,
  email: String,
  password: String,
  confirm_password: String,
) -> List(#(String, String)) {
  [
    #("first_name", first_name),
    #("last_name", last_name),
    #("email", email),
    #("password", password),
    #("confirm_password", confirm_password),
  ]
}

fn validate_form_params(
  values: List(#(String, String)),
) -> Result(RegisterParams, Errors) {
  ve.parse_form(register_schema(), values, [
    ve.cross("confirm_password", passwords_must_match),
  ])
  |> result.map_error(ErrorValidatingParams)
}

pub fn parse_form_registration_validates_successfully_test() {
  let values =
    form_payload("Jim", "Bean", "testing@test.com", "qwerty123", "qwerty123")

  let actual = validate_form_params(values)
  assert actual
    == Ok(RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "testing@test.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    ))
}

pub fn parse_form_registration_accumulates_field_errors_test() {
  let values = form_payload("", "Bean", "not-an-email", "qwe", "qwe")

  let actual = validate_form_params(values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "first_name", value: "This field is required"),
        ValidationError(key: "email", value: "Email address is not valid"),
        ValidationError(
          key: "password",
          value: "Password must be a minimum of 8 characters",
        ),
      ]),
    )

  assert actual == expected
}

// ================== End-to-end with a JSON fixture ===================

pub fn json_registration_validates_successfully_test() {
  let data = fixtures.load("valid_registration.json")

  let actual = validate_params(data)
  assert actual
    == Ok(RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "testing@test.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    ))
}

pub fn json_registration_returns_validation_errors_test() {
  let data = fixtures.load("invalid_registration.json")

  let actual = validate_params(data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "first_name", value: "This field is required"),
        ValidationError(key: "email", value: "Email address is not valid"),
        ValidationError(
          key: "password",
          value: "Password must be a minimum of 8 characters",
        ),
      ]),
    )

  assert actual == expected
}
