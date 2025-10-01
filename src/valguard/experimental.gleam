//// Experimental features

import gleam/bool
import gleam/result

/// A general type of validation that is returned as a list
pub type Validation {
  Validation(key: String, success: Bool, message: String, error_code: String)
}

/// a single validation item that contains a list of issues
///
/// This model could then be one part of a result or enum
// pub type ValidationV2 {
//   ValidationV2(success: Bool, issues: List(Issue))
// }

pub type ValidationError {
  ValidationError(key: String, message: String, error_code: String)
}

/// not sure on naming
pub type Issue {
  Issue(key: String, message: String, error: Error)
}

/// Another option, where returned validation is either success,
/// which will include the validated params
///
/// Or, it will be a validation error and include a list of issues
pub type ValidationType(a) {
  Success(a)
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
  list: List(fn(value) -> Validation),
) -> Result(Nil, ValidationError) {
  // recursively check list of validations
  case with_inner(list, value, Ok(Nil)) {
    Ok(Nil) -> Ok(Nil)
    Error(message) ->
      Error(ValidationError(
        key:,
        message:,
        error_code: error_code(StringRequired),
      ))
  }
}

/// Inner recursive loop for with
// fn with_inner(
//   list: List(fn(value) -> Result(Nil, String)),
//   value,
//   prev: Result(Nil, String),
// ) -> Result(Nil, String) {
//   // return early if previous value was error
//   use _ <- result.try(prev)
//   case list {
//     [] -> prev
//     [next, ..rest] -> with_inner(rest, value, next(value))
//   }
// }

/// Inner recursive loop for with
fn with_inner(
  list: List(fn(value) -> Validation),
  value,
  prev: Validation,
) -> Validation {
  // return early if previous value was error
  use <- bool.guard(when: !prev.success, return: prev)

  case list {
    [] -> prev
    [next, ..rest] -> with_inner(rest, value, next(value))
  }
}

pub fn testing() {
  echo "Testing types and shapes"

  let result = with("email", "t@test.com", [])
  echo result
}

fn check_email(value: String) -> Validation {
  todo
}
