//// Experimental: curried validation predicates for use with the typed field
//// combinators in `valguard/experimental`.
////
//// Each function takes the parameters for the check (and a message) and
//// returns a `Predicate(t)`. Composed with `field_with`, `string_field`,
//// `int_field`, etc. as the list of validations:
////
//// ```gleam
//// use email <- ve.string_field("email", "Email is required", [
////   ev.email_is_valid("Invalid email"),
//// ])
//// ```
////
//// Required-ness is NOT a predicate concern — use `string_field` / `int_field`
//// etc. for that, and reach for the optional variants when a field can be
//// omitted.

import gleam/regexp
import gleam/result
import gleam/string
import gleam/time/timestamp
import valguard/experimental.{type Predicate}
import youid/uuid

const email_regex_pattern: String = "^[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

// ================== String predicates ===================

/// Fails if the string is empty.
pub fn string_not_empty(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.is_empty(value) {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

/// Fails if the string is shorter than `min` characters.
pub fn string_min(min: Int, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.length(value) < min {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

/// Fails if the string is longer than `max` characters.
pub fn string_max(max: Int, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.length(value) > max {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

/// Fails if the string is not exactly `len` characters long.
pub fn string_length(len: Int, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.length(value) == len {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the string does not start with `prefix`.
pub fn string_starts_with(prefix: String, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.starts_with(value, prefix) {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the string does not end with `suffix`.
pub fn string_ends_with(suffix: String, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.ends_with(value, suffix) {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the string does not contain `substring`.
pub fn string_contains(substring: String, message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case string.contains(value, substring) {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

// ================== Format predicates ===================

/// Fails if the string is not a valid email address.
pub fn email_is_valid(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    use re <- result.try(
      regexp.from_string(email_regex_pattern)
      |> result.replace_error(message),
    )
    case regexp.check(re, value) {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the string is not a valid RFC3339 date/time.
pub fn date_is_valid(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) {
    case timestamp.parse_rfc3339(value) {
      Ok(_) -> Ok(Nil)
      Error(_) -> Error(message)
    }
  }
}

/// Fails if the string is not a valid UUID v1.
pub fn uuid_v1(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V1, message) }
}

/// Fails if the string is not a valid UUID v2.
pub fn uuid_v2(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V2, message) }
}

/// Fails if the string is not a valid UUID v3.
pub fn uuid_v3(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V3, message) }
}

/// Fails if the string is not a valid UUID v4.
pub fn uuid_v4(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V4, message) }
}

/// Fails if the string is not a valid UUID v5.
pub fn uuid_v5(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V5, message) }
}

/// Fails if the string is not a valid UUID v7.
pub fn uuid_v7(message: String) -> Predicate(String) {
  fn(value: String) -> Result(Nil, String) { check_uuid_version(value, uuid.V7, message) }
}

// ================== Int predicates ===================

/// Fails if the int is less than `min`.
pub fn int_min(min: Int, message: String) -> Predicate(Int) {
  fn(value: Int) -> Result(Nil, String) {
    case value < min {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

/// Fails if the int is greater than `max`.
pub fn int_max(max: Int, message: String) -> Predicate(Int) {
  fn(value: Int) -> Result(Nil, String) {
    case value > max {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

// ================== Float predicates ===================

/// Fails if the float is less than `min`.
pub fn float_min(min: Float, message: String) -> Predicate(Float) {
  fn(value: Float) -> Result(Nil, String) {
    case value <. min {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

/// Fails if the float is greater than `max`.
pub fn float_max(max: Float, message: String) -> Predicate(Float) {
  fn(value: Float) -> Result(Nil, String) {
    case value >. max {
      True -> Error(message)
      False -> Ok(Nil)
    }
  }
}

// ================== Bool predicates ===================

/// Fails if the bool is not `True`.
pub fn bool_true(message: String) -> Predicate(Bool) {
  fn(value: Bool) -> Result(Nil, String) {
    case value {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the bool is not `False`.
pub fn bool_false(message: String) -> Predicate(Bool) {
  fn(value: Bool) -> Result(Nil, String) {
    case value {
      False -> Ok(Nil)
      True -> Error(message)
    }
  }
}

// ================== Internal ===================

fn check_uuid_version(value: String, ver: uuid.Version, message: String) -> Result(Nil, String) {
  case uuid.from_string(value) {
    Error(_) -> Error(message)
    Ok(u) ->
      case uuid.version(u) == ver {
        True -> Ok(Nil)
        False -> Error(message)
      }
  }
}
