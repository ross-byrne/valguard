import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp
import valguard/internal/utils
import youid/uuid

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

/// Validates a string is a defined length
pub fn string_length(
  value: String,
  len len: Int,
  message message: String,
) -> Result(Nil, String) {
  case string.length(value) == len {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string starts with a value
pub fn string_starts_with(
  value: String,
  with with: String,
  message message: String,
) -> Result(Nil, String) {
  case string.starts_with(value, with) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string ends with a value
pub fn string_ends_with(
  value: String,
  with with: String,
  message message: String,
) -> Result(Nil, String) {
  case string.ends_with(value, with) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string contains a value
pub fn string_contains(
  value: String,
  contains contains: String,
  message message: String,
) -> Result(Nil, String) {
  case string.contains(value, contains) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V1
pub fn uuid_v1(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V1) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V2
pub fn uuid_v2(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V2) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V3
pub fn uuid_v3(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V3) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V4
pub fn uuid_v4(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V4) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V5
pub fn uuid_v5(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V5) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

/// Validates a string is a valid UUID V7
pub fn uuid_v7(value: String, message message: String) -> Result(Nil, String) {
  case utils.check_uuid_version(value, uuid.V7) {
    True -> Ok(Nil)
    False -> Error(message)
  }
}

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
