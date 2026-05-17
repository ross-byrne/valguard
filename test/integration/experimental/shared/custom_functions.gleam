//// Custom validation functions for the experimental integration tests.
////
//// These follow the convention that custom predicates encapsulate BOTH the
//// check AND its failure message — users defining their own predicates
//// shouldn't have to repeat the same message at every call site.
////
//// Predicates that need context (like a DB connection) take that context
//// and return a `Predicate(t)`, matching the curried shape of `ev`:
////
//// ```gleam
//// cf.user_email_is_available(db),
//// ```
////
//// Self-contained predicates (no context needed) return
//// `Result(Nil, String)` directly — already the `Predicate(t)` shape:
////
//// ```gleam
//// cf.password_requirements,
//// ```
////
//// Cross-field helpers (`passwords_match`) take both values and return
//// `Result(Nil, String)` — callers wrap into a `ValidationError` keyed to
//// the right field at the `success_with` boundary.

import gleam/string
import valguard/experimental.{type Predicate}

/// Custom validation function that takes a database connection and returns
/// a `Predicate(String)`. The error message lives inside the function where
/// the failure case is defined.
pub fn user_email_is_available(_db) -> Predicate(String) {
  fn(email) {
    // Pretend we're checking the db here.
    case email != "email@taken.com" {
      True -> Ok(Nil)
      False -> Error("Email address is not available")
    }
  }
}

/// Composite predicate that runs multiple internal checks with their own
/// messages. Self-contained — no dependency on `valguard/validate`.
pub fn password_requirements(password: String) -> Result(Nil, String) {
  case string.length(password) {
    n if n < 8 -> Error("Password must be a minimum of 8 characters")
    n if n > 64 -> Error("Password must be a maximum of 64 characters")
    _ -> Ok(Nil)
  }
}

/// Cross-field check that password and confirm_password are equal.
pub fn passwords_match(
  password: String,
  confirm: String,
) -> Result(Nil, String) {
  case password == confirm {
    True -> Ok(Nil)
    False -> Error("Password & Confirm Password must match")
  }
}
