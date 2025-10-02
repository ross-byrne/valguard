import gleam/float
import gleam/int
import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp

/// Regex for validating emails. Used by HTML5 email input type
///
/// See spec: https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
const email_regex_pattern: String = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

/// Requires a int to be less than or greater than 0 to be considered required
@deprecated("use valguard module instead")
pub fn int_required(value: Int) -> Result(Nil, String) {
  case value != 0 {
    True -> Ok(Nil)
    False -> Error("This field is required")
  }
}

/// Validates an int is at least a minimum value. Returns an error if value is less than the minimum
@deprecated("use valguard module instead")
pub fn int_min(value: Int, min minimum: Int) -> Result(Nil, String) {
  case value < minimum {
    True -> Error("Value must be a minimum of " <> int.to_string(minimum))
    False -> Ok(Nil)
  }
}

/// Validates an int is at most a maximum value. Returns an error if value is greater than the maximum
@deprecated("use valguard module instead")
pub fn int_max(value: Int, max maximum: Int) -> Result(Nil, String) {
  case value > maximum {
    True -> Error("Value must be a maximum of " <> int.to_string(maximum))
    False -> Ok(Nil)
  }
}

/// Requires a float to be less than or greater than 0.0 to be considered required
@deprecated("use valguard module instead")
pub fn float_required(value: Float) -> Result(Nil, String) {
  case value >. 0.0 || value <. 0.0 {
    True -> Ok(Nil)
    False -> Error("This field is required")
  }
}

/// Validates an float is at least a minimum value. Returns an error if value is less than the minimum
@deprecated("use valguard module instead")
pub fn float_min(value: Float, min minimum: Float) -> Result(Nil, String) {
  case value <. minimum {
    True -> Error("Value must be a minimum of " <> float.to_string(minimum))
    False -> Ok(Nil)
  }
}

/// Validates an float is at most a maximum value. Returns an error if value is greater than the maximum
@deprecated("use valguard module instead")
pub fn float_max(value: Float, max maximum: Float) -> Result(Nil, String) {
  case value >. maximum {
    True -> Error("Value must be a maximum of " <> float.to_string(maximum))
    False -> Ok(Nil)
  }
}

/// Requires a string to not be empty to be considered required
@deprecated("use valguard module instead")
pub fn string_required(value: String) -> Result(Nil, String) {
  case string.is_empty(value) {
    False -> Ok(Nil)
    True -> Error("This field is required")
  }
}

/// Validates a string is a minimum length
@deprecated("use valguard module instead")
pub fn string_min(value: String, min minimum: Int) -> Result(Nil, String) {
  case string.length(value) < minimum {
    True ->
      Error(
        "Value must be a minimum of " <> int.to_string(minimum) <> " characters",
      )
    False -> Ok(Nil)
  }
}

/// Validates a string is at most a maximum length
@deprecated("use valguard module instead")
pub fn string_max(value: String, max maximum: Int) -> Result(Nil, String) {
  case string.length(value) > maximum {
    True ->
      Error(
        "Value must be a maximum of " <> int.to_string(maximum) <> " characters",
      )
    False -> Ok(Nil)
  }
}

/// Validates if entered email is a valid email address
@deprecated("use valguard module instead")
pub fn email_is_valid(email: String) -> Result(Nil, String) {
  let error = "Email address is not valid"

  use re <- result.try(
    regexp.from_string(email_regex_pattern)
    |> result.replace_error(error),
  )

  case regexp.check(re, email) {
    False -> Error(error)
    True -> Ok(Nil)
  }
}

/// Validates that a date is valid by checking it can be parsed correctly
@deprecated("use valguard module instead")
pub fn date_is_valid(datetime: String) -> Result(Nil, String) {
  case timestamp.parse_rfc3339(datetime) {
    Ok(_) -> Ok(Nil)
    Error(_) -> Error("A valid date is required")
  }
}
