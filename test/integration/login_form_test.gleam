//// Integration test to show how a login form might be validated
////
//// Shows how to wrap the validation errors in your own custom error type

import valguard.{type ValidationError, ValidationError}
import valguard/val

// ================== Test setup ===================

type LoginParams {
  LoginParams(email: String, password: String)
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

/// Validates login params
fn validate_params(params: LoginParams) -> Result(Nil, Errors) {
  [
    valguard.with("email", params.email, [
      val.string_required(_, "This field is required"),
      val.email_is_valid(_, "Email address is not valid"),
    ]),
    valguard.with("password", params.password, [
      val.string_required(_, "This field is required"),
    ]),
  ]
  |> valguard.collect_errors
  |> valguard.prepare_with(ErrorValidatingParams)
}

// ================== Tests ===================

pub fn login_form_validates_successfully_test() {
  let params = LoginParams(email: "testing@test.com", password: "qwerty")
  let result = validate_params(params)
  assert result == Ok(Nil)
}

pub fn login_form_is_missing_fields_test() {
  let params = LoginParams(email: "", password: "")
  let actual = validate_params(params)
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
  let params = LoginParams(email: "not an email", password: "qwerty")
  let actual = validate_params(params)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
      ]),
    )

  assert actual == expected
}
