import gleam/list
import gleam/option.{type Option}
import gleam/result
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
