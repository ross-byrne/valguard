//// Integration test to show how a user registeration form might be validated
////
//// Shows how to wrap the validation errors in your own custom error type
//// and the use of custom validation functions, one of which takes a database connection

import gleam/result
import valguard.{type ValidationError, ValidationError}
import valguard/val

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

/// Custom validation function that takes a database connection
fn user_email_is_available(
  _db: Connection,
  email: String,
) -> Result(Nil, String) {
  // make your db call here
  case email != "email@taken.com" {
    True -> Ok(Nil)
    False -> Error("Email address is not available")
  }
}

/// Validates that password and confirm password match
fn passwords_match(password: String, confirm: String) -> Result(Nil, String) {
  case password == confirm {
    True -> Ok(Nil)
    False -> Error("Password & Confirm Password must match")
  }
}

/// Validates password requirements
fn password_requirements(password: String) -> Result(Nil, String) {
  // enforce minimum password length of 8 characters and max of 64
  use _ <- result.try(
    val.string_min(password, min: 8)
    |> result.replace_error("Password must be a minimum of 8 characters"),
  )
  use _ <- result.try(
    val.string_max(password, max: 64)
    |> result.replace_error("Password must be a maximum of 64 characters"),
  )

  Ok(Nil)
}

/// Validates register params
fn validate_params(
  db: Connection,
  params: RegisterParams,
) -> Result(Nil, Errors) {
  [
    valguard.with("first_name", params.first_name, [val.string_required]),
    valguard.with("last_name", params.last_name, [val.string_required]),
    valguard.with("email", params.email, [
      val.string_required,
      val.email_is_valid,
      user_email_is_available(db, _),
    ]),
    valguard.with("password", params.password, [
      val.string_required,
      password_requirements,
    ]),
    valguard.with("confirm_password", params.confirm_password, [
      val.string_required,
      fn(_) { passwords_match(params.password, params.confirm_password) },
    ]),
  ]
  |> valguard.collect_errors
  |> valguard.prepare_with(ErrorValidatingParams)
}

// ================== Tests ===================

pub fn register_form_validates_successfully_test() {
  // simulate a database connection
  let db = Connection
  let params =
    RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "testing@test.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    )

  let result = validate_params(db, params)
  assert result == Ok(Nil)
}

pub fn register_form_is_missing_fields_test() {
  // simulate a database connection
  let db = Connection
  let params =
    RegisterParams(
      first_name: "",
      last_name: "",
      email: "",
      password: "",
      confirm_password: "",
    )

  let actual = validate_params(db, params)
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
  // simulate a database connection
  let db = Connection
  let params =
    RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "email@taken.com",
      password: "qwerty123",
      confirm_password: "qwerty123",
    )

  let actual = validate_params(db, params)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not available"),
      ]),
    )

  assert actual == expected
}

pub fn register_form_password_is_too_short_test() {
  // simulate a database connection
  let db = Connection
  let params =
    RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "test@test.com",
      password: "qwe",
      confirm_password: "qwe",
    )

  let actual = validate_params(db, params)
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
  // simulate a database connection
  let db = Connection
  let params =
    RegisterParams(
      first_name: "Jim",
      last_name: "Bean",
      email: "test@test.com",
      password: "qwerty123",
      confirm_password: "asdfgh1235",
    )

  let actual = validate_params(db, params)
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
