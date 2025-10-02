//// Experimental features

import gleam/option.{type Option, None, Some}
import gleam/result

/// A general type of validation that is returned as a list
// pub type Validation {
//   Validation(key: String, message: String, error_code: String)
// }

/// a single validation item that contains a list of issues
///
/// This model could then be one part of a result or enum
// pub type ValidationV2 {
//   ValidationV2(success: Bool, issues: List(Issue))
// }

pub type ValidationError {
  ValidationError(message: String, error_code: String)
}

/// not sure on naming
pub type Issue {
  Issue(key: String, message: String, error_code: String)
}

/// Another option, where returned validation is either success,
/// which will include the validated params
///
/// Or, it will be a validation error and include a list of issues
pub type ValidationType {
  Success
  ValError(List(Issue))
}

/// A list of all types of validation errors that can occur
pub type VError {
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
pub fn error_code(error: VError) -> String {
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
  list: List(fn(value) -> Result(Nil, ValidationError)),
) -> Result(Nil, Issue) {
  // recursively check list of validations
  case with_inner(list, value, Ok(Nil)) {
    Ok(Nil) -> Ok(Nil)
    Error(ValidationError(message:, error_code:)) ->
      Error(Issue(key:, message:, error_code:))
  }
}

/// Inner recursive loop for with
fn with_inner(
  list: List(fn(value) -> Result(Nil, ValidationError)),
  value,
  prev: Result(Nil, ValidationError),
) -> Result(Nil, ValidationError) {
  // return early if previous value was error
  use _ <- result.try(prev)
  case list {
    [] -> prev
    [next, ..rest] -> with_inner(rest, value, next(value))
  }
}

/// testing a validation
pub fn test_validation(
  value: String,
  message: Option(String),
) -> Result(Nil, ValidationError) {
  let message = option.unwrap(message, "string does not match")

  case value == "true" {
    True -> Ok(Nil)
    False ->
      Error(ValidationError(message:, error_code: error_code(StringNotEqual)))
  }
}

// pub fn with(
//   key: String,
//   value,
//   list: List(fn(value) -> Validation),
// ) -> ValidationType {
//   // recursively check list of validations
//   case with_inner(list, value, Success) {
//     Success -> Success
//     ValError -> ValError
//   }
// }

/// Inner recursive loop for with
// fn with_inner(
//   list: List(fn(value) -> ValidationType),
//   value,
//   prev: ValidationType,
// ) -> ValidationType {
//   // return early if previous value was error
//   use <- bool.guard(when: prev != Success, return: prev)

//   case list {
//     [] -> prev
//     [next, ..rest] -> with_inner(rest, value, next(value))
//   }
// }

pub fn testing() {
  echo "Testing types and shapes"

  let result =
    with("email", "t@test.com", [
      test_validation(_, Some("Valid email required")),
      test_validation(_, None),
    ])
  echo result
}
