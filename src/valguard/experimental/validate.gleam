//// Experimental: curried validation predicates for use with the typed field
//// combinators in `valguard/experimental`.
////
//// Each function takes the parameters for the check (and a message) and
//// returns a `Predicate(t)`. Composed with `field_with`, `string_field`,
//// `int_field`, etc. as the list of validations:
////
//// ```gleam
//// use email <- ve.string_field("email", "Email is required", [
////   ev.string_not_empty("Email is required"),
////   ev.email_is_valid("Invalid email"),
//// ])
//// ```
////
//// Each predicate is a thin curry over the equivalent function in
//// `valguard/validate`. Required-ness is NOT a predicate concern — use
//// `string_field` / `int_field` etc. for that, and reach for the optional
//// variants when a field can be omitted.

import valguard/experimental.{type Predicate}
import valguard/validate as v

// ================== String predicates ===================

/// Fails if the string is empty.
pub fn string_not_empty(message: String) -> Predicate(String) {
  v.string_required(_, message)
}

/// Fails if the string is shorter than `min` characters.
pub fn string_min(min: Int, message: String) -> Predicate(String) {
  v.string_min(_, min, message)
}

/// Fails if the string is longer than `max` characters.
pub fn string_max(max: Int, message: String) -> Predicate(String) {
  v.string_max(_, max, message)
}

/// Fails if the string is not exactly `len` characters long.
pub fn string_length(len: Int, message: String) -> Predicate(String) {
  v.string_length(_, len, message)
}

/// Fails if the string does not start with `prefix`.
pub fn string_starts_with(
  prefix: String,
  message: String,
) -> Predicate(String) {
  v.string_starts_with(_, prefix, message)
}

/// Fails if the string does not end with `suffix`.
pub fn string_ends_with(suffix: String, message: String) -> Predicate(String) {
  v.string_ends_with(_, suffix, message)
}

/// Fails if the string does not contain `substring`.
pub fn string_contains(
  substring: String,
  message: String,
) -> Predicate(String) {
  v.string_contains(_, substring, message)
}

// ================== Format predicates ===================

/// Fails if the string is not a valid email address.
pub fn email_is_valid(message: String) -> Predicate(String) {
  v.email_is_valid(_, message)
}

/// Fails if the string is not a valid RFC3339 date/time.
pub fn date_is_valid(message: String) -> Predicate(String) {
  v.date_is_valid(_, message)
}

/// Fails if the string is not a valid UUID v1.
pub fn uuid_v1(message: String) -> Predicate(String) {
  v.uuid_v1(_, message)
}

/// Fails if the string is not a valid UUID v2.
pub fn uuid_v2(message: String) -> Predicate(String) {
  v.uuid_v2(_, message)
}

/// Fails if the string is not a valid UUID v3.
pub fn uuid_v3(message: String) -> Predicate(String) {
  v.uuid_v3(_, message)
}

/// Fails if the string is not a valid UUID v4.
pub fn uuid_v4(message: String) -> Predicate(String) {
  v.uuid_v4(_, message)
}

/// Fails if the string is not a valid UUID v5.
pub fn uuid_v5(message: String) -> Predicate(String) {
  v.uuid_v5(_, message)
}

/// Fails if the string is not a valid UUID v7.
pub fn uuid_v7(message: String) -> Predicate(String) {
  v.uuid_v7(_, message)
}

// ================== Int predicates ===================

/// Fails if the int is less than `min`.
pub fn int_min(min: Int, message: String) -> Predicate(Int) {
  v.int_min(_, min, message)
}

/// Fails if the int is greater than `max`.
pub fn int_max(max: Int, message: String) -> Predicate(Int) {
  v.int_max(_, max, message)
}

// ================== Float predicates ===================

/// Fails if the float is less than `min`.
pub fn float_min(min: Float, message: String) -> Predicate(Float) {
  v.float_min(_, min, message)
}

/// Fails if the float is greater than `max`.
pub fn float_max(max: Float, message: String) -> Predicate(Float) {
  v.float_max(_, max, message)
}

// ================== Bool predicates ===================

/// Fails if the bool is not `True`.
pub fn bool_true(message: String) -> Predicate(Bool) {
  fn(value) {
    case value {
      True -> Ok(Nil)
      False -> Error(message)
    }
  }
}

/// Fails if the bool is not `False`.
pub fn bool_false(message: String) -> Predicate(Bool) {
  fn(value) {
    case value {
      False -> Ok(Nil)
      True -> Error(message)
    }
  }
}
