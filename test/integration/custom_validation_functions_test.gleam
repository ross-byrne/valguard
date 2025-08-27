//// Integration test to show how custom validation functions can be used

import integration/shared/custom_functions.{Connection} as cf
import valguard.{ValidationError}

pub fn custom_validation_function_passes_test() {
  let actual =
    valguard.with("password", "my-password", [cf.password_requirements])
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn custom_validation_function_fails_test() {
  let actual = valguard.with("password", "asdf", [cf.password_requirements])
  let expected =
    Error(ValidationError(
      key: "password",
      value: "Password must be a minimum of 8 characters",
    ))
  assert actual == expected
}

pub fn custom_multi_param_validation_function_passes_test() {
  let actual =
    valguard.list("confirm_password", [
      fn() { cf.passwords_match("password", "password") },
    ])
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn custom_multi_param_validation_function_fails_test() {
  let actual =
    valguard.list("confirm_password", [
      fn() { cf.passwords_match("password", "wrong-password") },
    ])
  let expected =
    Error(ValidationError(
      key: "confirm_password",
      value: "Password & Confirm Password must match",
    ))
  assert actual == expected
}

pub fn custom_validation_function_with_database_connection_passes_test() {
  let db = Connection
  let actual =
    valguard.with("email", "example@test.com", [
      cf.user_email_is_available(db, _),
    ])
  let expected = Ok(Nil)

  assert actual == expected
}

pub fn custom_validation_function_with_database_connection_fails_test() {
  let db = Connection
  let actual =
    valguard.with("email", "email@taken.com", [
      cf.user_email_is_available(db, _),
    ])
  let expected =
    Error(ValidationError("email", "Email address is not available"))

  assert actual == expected
}
