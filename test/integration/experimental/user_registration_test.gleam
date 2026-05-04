//// Integration test mirroring user_registeration_test.gleam against the
//// experimental parse + validate pipeline.
////
//// Demonstrates the recommended two-phase pattern: ve.parse handles parsing
//// and per-field validation, then valguard.list runs cross-field checks
//// (passwords_match) only after the parse has succeeded.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import integration/experimental/shared/fixtures
import integration/shared/custom_functions as cf
import valguard.{type ValidationError, ValidationError}
import valguard/experimental as ve
import valguard/validate as v

// ================== Test setup ===================

type Connection {
  Connection
}

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

fn register_schema(db: Connection) -> ve.Schema(RegisterParams) {
  let required = "This field is required"
  use first_name <- ve.field_with("first_name", decode.string, [
    v.string_required(_, required),
  ])
  use last_name <- ve.field_with("last_name", decode.string, [
    v.string_required(_, required),
  ])
  use email <- ve.field_with("email", decode.string, [
    v.string_required(_, required),
    v.email_is_valid(_, "Email address is not valid"),
    cf.user_email_is_available(db, _),
  ])
  use password <- ve.field_with("password", decode.string, [
    v.string_required(_, required),
    cf.password_requirements,
  ])
  use confirm_password <- ve.field_with("confirm_password", decode.string, [
    v.string_required(_, required),
  ])

  decode.success(RegisterParams(
    first_name,
    last_name,
    email,
    password,
    confirm_password,
  ))
}

fn validate_params(
  db: Connection,
  data: dynamic.Dynamic,
) -> Result(RegisterParams, Errors) {
  // Phase 1: parse + per-field. All accumulated errors come back at once.
  use params <- result.try(
    ve.parse(register_schema(db), data)
    |> result.map_error(ErrorValidatingParams),
  )

  // Phase 2: cross-field. Only runs when phase 1 succeeded, so the cross-field
  // check never sees placeholder values from a failed earlier decode.
  let cross_field_errors =
    [
      valguard.list("confirm_password", [
        fn() { cf.passwords_match(params.password, params.confirm_password) },
      ]),
    ]
    |> valguard.collect_errors

  case cross_field_errors {
    [] -> Ok(params)
    errors -> Error(ErrorValidatingParams(errors))
  }
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
  let db = Connection
  let data =
    payload("Jim", "Bean", "testing@test.com", "qwerty123", "qwerty123")

  let result = validate_params(db, data)
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
  // Real HTML forms always submit keys; empty inputs arrive as "". The schema's
  // string_required predicates handle the "blank" case. (For JSON APIs where
  // a key may be genuinely absent, use optional_field_with with a default.)
  let db = Connection
  let data = payload("", "", "", "", "")

  let actual = validate_params(db, data)
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

pub fn register_form_email_is_taken_test() {
  let db = Connection
  let data = payload("Jim", "Bean", "email@taken.com", "qwerty123", "qwerty123")

  let actual = validate_params(db, data)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not available"),
      ]),
    )

  assert actual == expected
}

pub fn register_form_password_is_too_short_test() {
  let db = Connection
  let data = payload("Jim", "Bean", "test@test.com", "qwe", "qwe")

  let actual = validate_params(db, data)
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
  let db = Connection
  let data = payload("Jim", "Bean", "test@test.com", "qwerty123", "asdfgh1235")

  let actual = validate_params(db, data)
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

// ================== End-to-end with a JSON fixture ===================

pub fn json_registration_validates_successfully_test() {
  let db = Connection
  let data = fixtures.load("valid_registration.json")

  let actual = validate_params(db, data)
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
  let db = Connection
  let data = fixtures.load("invalid_registration.json")

  let actual = validate_params(db, data)
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

// ================== success_with one-pass alternative ===================
//
// Same end-to-end behavior as the two-phase pattern above, but cross-field
// checks live inside the schema. Use this when you want a single pipeline and
// accept that cross-field checks may run against placeholder values when an
// earlier field decode failed.

fn register_schema_one_pass(db: Connection) -> ve.Schema(RegisterParams) {
  let required = "This field is required"
  use first_name <- ve.field_with("first_name", decode.string, [
    v.string_required(_, required),
  ])
  use last_name <- ve.field_with("last_name", decode.string, [
    v.string_required(_, required),
  ])
  use email <- ve.field_with("email", decode.string, [
    v.string_required(_, required),
    v.email_is_valid(_, "Email address is not valid"),
    cf.user_email_is_available(db, _),
  ])
  use password <- ve.field_with("password", decode.string, [
    v.string_required(_, required),
    cf.password_requirements,
  ])
  use confirm_password <- ve.field_with("confirm_password", decode.string, [
    v.string_required(_, required),
  ])

  ve.success_with(
    RegisterParams(first_name, last_name, email, password, confirm_password),
    [
      fn(p: RegisterParams) {
        cf.passwords_match(p.password, p.confirm_password)
        |> result.map_error(ValidationError("confirm_password", _))
      },
    ],
  )
}

pub fn one_pass_register_form_passwords_dont_match_test() {
  let db = Connection
  let data = payload("Jim", "Bean", "test@test.com", "qwerty123", "asdfgh1235")

  let actual =
    ve.parse(register_schema_one_pass(db), data)
    |> result.map_error(ErrorValidatingParams)
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

pub fn one_pass_register_form_validates_successfully_test() {
  let db = Connection
  let data =
    payload("Jim", "Bean", "testing@test.com", "qwerty123", "qwerty123")

  let result = ve.parse(register_schema_one_pass(db), data)
  assert result
    == Ok(RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "testing@test.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    ))
}

// Demonstrates the success_with caveat: when password and confirm_password are
// both empty, the per-field "required" errors fire AND passwords_match("", "")
// silently returns Ok against the placeholder values, so no cross-field error
// surfaces. Use the two-phase pattern when this matters.
pub fn one_pass_cross_field_runs_against_placeholder_values_test() {
  let db = Connection
  let data = payload("Jim", "Bean", "test@test.com", "", "")

  let actual =
    ve.parse(register_schema_one_pass(db), data)
    |> result.map_error(ErrorValidatingParams)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "password", value: "This field is required"),
        ValidationError(
          key: "confirm_password",
          value: "This field is required",
        ),
      ]),
    )

  assert actual == expected
}
