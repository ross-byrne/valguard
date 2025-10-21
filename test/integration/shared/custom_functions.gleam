//// Custom validation functions to use in integration tests

import gleam/result
import valguard/validate as v

/// Custom validation function that takes a database connection
pub fn user_email_is_available(_db, email: String) -> Result(Nil, String) {
  // make your db call here
  case email != "email@taken.com" {
    True -> Ok(Nil)
    False -> Error("Email address is not available")
  }
}

/// Validates password requirements
pub fn password_requirements(password: String) -> Result(Nil, String) {
  // enforce minimum password length of 8 characters and max of 64
  use _ <- result.try(v.string_min(
    password,
    min: 8,
    message: "Password must be a minimum of 8 characters",
  ))
  use _ <- result.try(v.string_max(
    password,
    max: 64,
    message: "Password must be a maximum of 64 characters",
  ))

  Ok(Nil)
}

/// Validates that password and confirm password match
pub fn passwords_match(password: String, confirm: String) -> Result(Nil, String) {
  case password == confirm {
    True -> Ok(Nil)
    False -> Error("Password & Confirm Password must match")
  }
}
