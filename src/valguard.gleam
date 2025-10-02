import gleam/list
import gleam/option.{type Option}
import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp
import valguard/internal/utils

/// Key/Value pair for encoding validation errors.
/// Key indicates the name of the field that failed validation
/// and Value is the error message.
pub type ValidationError {
  ValidationError(key: String, value: String)
}

/// Takes a validation result and list of validation errors
/// If result is error, it adds it to the list
pub fn append_error(
  result: Result(Nil, ValidationError),
  list: List(ValidationError),
) -> List(ValidationError) {
  case result {
    Error(validation_error) -> {
      list.append(list, [validation_error])
    }
    Ok(Nil) -> list
  }
}

/// Takes a list of validation results and returns a list of the errors
/// Returns an empty list if no errors
pub fn collect_errors(
  inputs: List(Result(Nil, ValidationError)),
) -> List(ValidationError) {
  // filter for errors
  list.filter_map(inputs, fn(x) {
    case x {
      Ok(Nil) -> Error(Nil)
      Error(validation_error) -> Ok(validation_error)
    }
  })
}

/// Takes a list of validation errors and converts it to a result
/// Returns ok if list is empty
pub fn prepare(
  errors: List(ValidationError),
) -> Result(Nil, List(ValidationError)) {
  case list.is_empty(errors) {
    True -> Ok(Nil)
    False -> Error(errors)
  }
}

/// Takes a list of validation errors and converts it to a result
/// wrapping the errors in a custom type. Returns Ok(Nil) if list is empty.
///
/// This functions similar to `valguard.prepare`.
pub fn prepare_with(
  errors: List(ValidationError),
  custom_type,
) -> Result(Nil, custom_type) {
  case list.is_empty(errors) {
    True -> Ok(Nil)
    False -> Error(custom_type(errors))
  }
}

/// Validates a list of requirements lazily.
///
/// Takes a key and list of validation functions.
///
/// Returns Ok(Nil) if success or Error(String) at first issue
pub fn list(
  key: String,
  list: List(fn() -> Result(Nil, String)),
) -> Result(Nil, ValidationError) {
  // recursively check list of validations
  case list_inner(list, Ok(Nil)) {
    Ok(Nil) -> Ok(Nil)
    Error(value) -> Error(ValidationError(key:, value:))
  }
}

/// Inner recursive loop for list
fn list_inner(
  list: List(fn() -> Result(Nil, String)),
  prev: Result(Nil, String),
) -> Result(Nil, String) {
  // return early if previous value was error
  use _ <- result.try(prev)
  case list {
    [] -> prev
    [next, ..rest] -> list_inner(rest, next())
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
  list: List(fn(value) -> Result(Nil, String)),
) -> Result(Nil, ValidationError) {
  // recursively check list of validations
  case with_inner(list, value, Ok(Nil)) {
    Ok(Nil) -> Ok(Nil)
    Error(value) -> Error(ValidationError(key:, value:))
  }
}

/// Validates a list of requirements lazily.
///
/// Takes a key, an optional value and list of validation functions.
///
/// Runs validation functions lazily and returns the result.
/// Returns Ok(Nil) if optional value is None or all validations are successful.
/// Returns Error(String) at first issue.
pub fn with_optional(
  key: String,
  option: Option(value),
  list: List(fn(value) -> Result(Nil, String)),
) -> Result(Nil, ValidationError) {
  // return early if option in None
  use value <- utils.some_or(option, return: Ok(Nil))

  // recursively check list of validations
  case with_inner(list, value, Ok(Nil)) {
    Ok(Nil) -> Ok(Nil)
    Error(value) -> Error(ValidationError(key:, value:))
  }
}

/// Inner recursive loop for with
fn with_inner(
  list: List(fn(value) -> Result(Nil, String)),
  value,
  prev: Result(Nil, String),
) -> Result(Nil, String) {
  // return early if previous value was error
  use _ <- result.try(prev)
  case list {
    [] -> prev
    [next, ..rest] -> with_inner(rest, value, next(value))
  }
}

// ================= Validation Functions =================

/// Regex for validating emails. Used by HTML5 email input type
///
/// See spec: https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
const email_regex_pattern: String = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

/// Requires a int to be less than or greater than 0 to be considered required
pub fn int_required(value: Int, message message: String) -> Result(Nil, String) {
  case value != 0 {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates an int is at least a minimum value. Returns an error if value is less than the minimum
pub fn int_min(
  value: Int,
  min minimum: Int,
  message message: String,
) -> Result(Nil, String) {
  case value < minimum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

/// Validates an int is at most a maximum value. Returns an error if value is greater than the maximum
pub fn int_max(
  value: Int,
  max maximum: Int,
  message message: String,
) -> Result(Nil, String) {
  case value > maximum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

/// Requires a float to be less than or greater than 0.0 to be considered required
pub fn float_required(
  value: Float,
  message message: String,
) -> Result(Nil, String) {
  case value >. 0.0 || value <. 0.0 {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a float is at least a minimum value. Returns an error if value is less than the minimum
pub fn float_min(
  value: Float,
  min minimum: Float,
  message message: String,
) -> Result(Nil, String) {
  case value <. minimum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

/// Validates a float is at most a maximum value. Returns an error if value is greater than the maximum
pub fn float_max(
  value: Float,
  max maximum: Float,
  message message: String,
) -> Result(Nil, String) {
  case value >. maximum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

/// Requires a string to not be empty to be considered required
pub fn string_required(
  value: String,
  message message: String,
) -> Result(Nil, String) {
  case string.is_empty(value) {
    False -> Ok(Nil)
    True -> Error(message)
  }
}

/// Validates a string is a minimum length
pub fn string_min(
  value: String,
  min minimum: Int,
  message message: String,
) -> Result(Nil, String) {
  case string.length(value) < minimum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

/// Validates a string is at most a maximum length
pub fn string_max(
  value: String,
  max maximum: Int,
  message message: String,
) -> Result(Nil, String) {
  case string.length(value) > maximum {
    True -> Error(message)
    False -> Ok(Nil)
  }
}

// TODO: add more string validations
// - starts_with
// - ends_with
// - includes
// - length
// - regex

/// Validates if entered email is a valid email address
pub fn email_is_valid(
  email: String,
  message message: String,
) -> Result(Nil, String) {
  use re <- result.try(
    regexp.from_string(email_regex_pattern)
    |> result.replace_error(message),
  )

  case regexp.check(re, email) {
    False -> Error(message)
    True -> Ok(Nil)
  }
}

/// Validates that a date is valid by checking it can be parsed correctly
pub fn date_is_valid(
  datetime: String,
  message message: String,
) -> Result(Nil, String) {
  case timestamp.parse_rfc3339(datetime) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error(message)
  }
}
