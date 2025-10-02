//// Experimental features. Leaning toward this.

import gleam/result

/// Type for holding overall validation for a key / value pair.
///
/// This error is one of the validation errors that have been triggered,
/// along with the value key
pub type ValidationError {
  ValidationError(key: String, issue: Issue)
}

/// Holds an individual validation issue.
///
/// Includes validation error message and error code
pub type Issue {
  Issue(message: String, error_code: String)
}

/// A list of all types of validation errors that can occur
type VError {
  StringRequired
  StringTooShort
  StringTooLong
  StringNotEqual
  IntRequired
  IntTooSmall
  IntTooLarge
  IntNotEqual
  FloatRequired
  FloatTooSmall
  FloatTooLarge
  FloatNotEqual
  BoolNotEqual
  TimestampNotValid
  TimestampNotEqual
  DateNotValid
  DateNotEqual
  EmailNotValid
}

/// convert error to error code
fn error_code(error: VError) -> String {
  case error {
    StringRequired -> "string_required"
    StringNotEqual -> "string_not_equal"
    StringTooLong -> "string_too_long"
    StringTooShort -> "string_too_short"
    IntNotEqual -> "int_not_equal"
    IntRequired -> "int_required"
    IntTooLarge -> "int_too_long"
    IntTooSmall -> "int_too_small"
    FloatNotEqual -> "float_not_equal"
    FloatRequired -> "float_required"
    FloatTooLarge -> "float_too_large"
    FloatTooSmall -> "float_too_small"
    BoolNotEqual -> "bool_not_equal"
    TimestampNotEqual -> "timestamp_not_equal"
    TimestampNotValid -> "timestamp_not_valid"
    DateNotValid -> "date_not_valid"
    DateNotEqual -> "date_not_equal"
    EmailNotValid -> "email_not_valid"
  }
}

/// Validates a list of requirements lazily.
///
/// Takes a key, value and list of validation functions.
///
/// Runs validation functions lazily and returns the result.
/// Returns Ok(Nil) if success or Error(String) at first issue
pub fn with(
  key: String,
  value,
  list: List(fn(value) -> Result(value, Issue)),
) -> Result(value, ValidationError) {
  // recursively check list of validations
  with_inner(list, value, Ok(value))
  |> result.map_error(fn(issue) { ValidationError(key:, issue:) })
}

/// Inner recursive loop for with
fn with_inner(
  list: List(fn(value) -> Result(value, Issue)),
  value,
  prev: Result(value, Issue),
) -> Result(value, Issue) {
  // return early if previous value was error
  use _ <- result.try(prev)
  case list {
    [] -> prev
    [next, ..rest] -> with_inner(rest, value, next(value))
  }
}

/// testing a validation
pub fn test_validation(value: String, message: String) -> Result(String, Issue) {
  case value == "true" {
    True -> Ok(value)
    False -> Error(Issue(message:, error_code: error_code(StringNotEqual)))
  }
}

pub fn testing() {
  echo "Testing types and shapes"

  let result =
    with("email", "t@test.com", [
      test_validation(_, "Valid email required"),
      test_validation(_, ""),
    ])
  echo result
}
