//// Integration test mirroring custom_validation_functions_test.gleam against
//// the experimental parse + validate pipeline.

import gleam/dynamic
import integration/experimental/shared/custom_functions as cf
import valguard.{ValidationError}
import valguard/experimental as ve

type Connection {
  Connection
}

// ================== Single-field predicate ===================

pub fn custom_validation_function_passes_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("my-password")),
    ])
  let schema = {
    use password <- ve.string_field("password", "Password is required", [
      cf.password_requirements,
    ])
    ve.success(password)
  }

  assert ve.parse(schema, data, []) == Ok("my-password")
}

pub fn custom_validation_function_fails_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("asdf")),
    ])
  let schema = {
    use password <- ve.string_field("password", "Password is required", [
      cf.password_requirements,
    ])
    ve.success(password)
  }

  let expected =
    Error([
      ValidationError(
        key: "password",
        value: "Password must be a minimum of 8 characters",
      ),
    ])
  assert ve.parse(schema, data, []) == expected
}

// ================== Post-parse via ve.validate ===================

pub fn custom_multi_param_validation_function_passes_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("password")),
      #(dynamic.string("confirm_password"), dynamic.string("password")),
    ])
  let schema = {
    use password <- ve.string_field("password", "Required", [])
    use confirm_password <- ve.string_field("confirm_password", "Required", [])
    ve.success(#(password, confirm_password))
  }

  let actual =
    ve.parse(schema, data, [
      ve.validate("confirm_password", fn(pair: #(String, String)) {
        let #(pw, confirm) = pair
        cf.passwords_match(pw, confirm)
      }),
    ])

  assert actual == Ok(#("password", "password"))
}

pub fn custom_multi_param_validation_function_fails_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("password")),
      #(dynamic.string("confirm_password"), dynamic.string("wrong-password")),
    ])
  let schema = {
    use password <- ve.string_field("password", "Required", [])
    use confirm_password <- ve.string_field("confirm_password", "Required", [])
    ve.success(#(password, confirm_password))
  }

  let actual =
    ve.parse(schema, data, [
      ve.validate("confirm_password", fn(pair: #(String, String)) {
        let #(pw, confirm) = pair
        cf.passwords_match(pw, confirm)
      }),
    ])

  let expected =
    Error([
      ValidationError(
        key: "confirm_password",
        value: "Password & Confirm Password must match",
      ),
    ])
  assert actual == expected
}

// ================== Predicate that closes over a DB connection ===================

pub fn custom_validation_function_with_database_connection_passes_test() {
  let db = Connection
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("example@test.com")),
    ])
  let schema = {
    use email <- ve.string_field("email", "Email is required", [
      cf.user_email_is_available(db),
    ])
    ve.success(email)
  }

  assert ve.parse(schema, data, []) == Ok("example@test.com")
}

pub fn custom_validation_function_with_database_connection_fails_test() {
  let db = Connection
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("email@taken.com")),
    ])
  let schema = {
    use email <- ve.string_field("email", "Email is required", [
      cf.user_email_is_available(db),
    ])
    ve.success(email)
  }

  let expected =
    Error([ValidationError("email", "Email address is not available")])
  assert ve.parse(schema, data, []) == expected
}
