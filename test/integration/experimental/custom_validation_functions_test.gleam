//// Integration test mirroring custom_validation_functions_test.gleam against
//// the experimental parse + validate pipeline.
////
//// Each scenario builds a small Dynamic payload, runs it through a schema
//// that uses field_with / success_with, and asserts on the resulting list
//// of ValidationErrors.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import integration/shared/custom_functions as cf
import valguard.{ValidationError}
import valguard/experimental as ve

type Connection {
  Connection
}

// ================== Single-field predicate (was valguard.with) ===================

pub fn custom_validation_function_passes_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("my-password")),
    ])
  let schema = {
    use password <- ve.field_with("password", decode.string, [
      cf.password_requirements,
    ])
    decode.success(password)
  }

  let actual = ve.parse(schema, data)
  let expected = Ok("my-password")
  assert actual == expected
}

pub fn custom_validation_function_fails_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("asdf")),
    ])
  let schema = {
    use password <- ve.field_with("password", decode.string, [
      cf.password_requirements,
    ])
    decode.success(password)
  }

  let actual = ve.parse(schema, data)
  let expected =
    Error([
      ValidationError(
        key: "password",
        value: "Password must be a minimum of 8 characters",
      ),
    ])
  assert actual == expected
}

// ================== Cross-field via success_with (was valguard.list) ===================

pub fn custom_multi_param_validation_function_passes_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("password")),
      #(dynamic.string("confirm_password"), dynamic.string("password")),
    ])
  let schema = {
    use password <- ve.field_with("password", decode.string, [])
    use confirm_password <- ve.field_with("confirm_password", decode.string, [])
    ve.success_with(#(password, confirm_password), [
      fn(pair) {
        let #(pw, confirm) = pair
        cf.passwords_match(pw, confirm)
        |> result.map_error(ValidationError("confirm_password", _))
      },
    ])
  }

  let actual = ve.parse(schema, data)
  let expected = Ok(#("password", "password"))
  assert actual == expected
}

pub fn custom_multi_param_validation_function_fails_test() {
  let data =
    dynamic.properties([
      #(dynamic.string("password"), dynamic.string("password")),
      #(dynamic.string("confirm_password"), dynamic.string("wrong-password")),
    ])
  let schema = {
    use password <- ve.field_with("password", decode.string, [])
    use confirm_password <- ve.field_with("confirm_password", decode.string, [])
    ve.success_with(#(password, confirm_password), [
      fn(pair) {
        let #(pw, confirm) = pair
        cf.passwords_match(pw, confirm)
        |> result.map_error(ValidationError("confirm_password", _))
      },
    ])
  }

  let actual = ve.parse(schema, data)
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
    use email <- ve.field_with("email", decode.string, [
      cf.user_email_is_available(db, _),
    ])
    decode.success(email)
  }

  let actual = ve.parse(schema, data)
  let expected = Ok("example@test.com")
  assert actual == expected
}

pub fn custom_validation_function_with_database_connection_fails_test() {
  let db = Connection
  let data =
    dynamic.properties([
      #(dynamic.string("email"), dynamic.string("email@taken.com")),
    ])
  let schema = {
    use email <- ve.field_with("email", decode.string, [
      cf.user_email_is_available(db, _),
    ])
    decode.success(email)
  }

  let actual = ve.parse(schema, data)
  let expected =
    Error([ValidationError("email", "Email address is not available")])
  assert actual == expected
}
