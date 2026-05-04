//// Experimental: parse + validate pipeline built on top of `gleam/dynamic/decode`.
////
//// A schema (`Schema(t)`, an alias for `decode.Decoder(t)`) parses raw
//// `Dynamic` input AND runs per-field validations in a single pass,
//// accumulating all errors. Pass the schema to `parse(schema, data)` to get
//// back either the typed record or a `List(ValidationError)`.
////
//// This module is experimental — the API may change before being promoted into
//// the main `valguard` module.

import gleam/dynamic/decode
import gleam/list
import gleam/string
import valguard.{type ValidationError, ValidationError}

// Sentinel used by success_with to round-trip ValidationError key/value pairs
// through DecodeError.expected (the Decoder type is opaque so we can't emit a
// custom error structure directly). Decoded back in
// decode_error_to_validation_error.
const ve_marker = "\u{0000}__valguard_ve__\u{0000}"

/// A parse + validate schema. Just an alias for `decode.Decoder(t)` — declare
/// schemas as functions returning a `Schema(t)` and pass them to `parse`.
pub type Schema(t) =
  decode.Decoder(t)

/// A field-level validation predicate. Returns `Ok(Nil)` if the value passes,
/// or `Error(message)` to attach `message` to the field's `ValidationError`.
pub type Predicate(t) =
  fn(t) -> Result(Nil, String)

/// Apply a schema to raw `Dynamic` input.
///
/// Returns the typed value on success, or every accumulated parse and
/// per-field validation error in one list.
pub fn parse(
  schema schema: Schema(t),
  data data: decode.Dynamic,
) -> Result(t, List(ValidationError)) {
  case decode.run(data, schema) {
    Ok(value) -> Ok(value)
    Error(errors) -> Error(list.map(errors, decode_error_to_validation_error))
  }
}

/// Decode a required field and validate it with a list of predicates.
///
/// Predicates run lazily for this field (short-circuit on first failure). Across
/// fields, errors accumulate via the underlying `decode.field` machinery, so a
/// schema with N field_with calls returns up to N errors at once.
pub fn field_with(
  field_name name: name,
  inner inner: decode.Decoder(t),
  validations validations: List(Predicate(t)),
  next next: fn(t) -> Schema(final),
) -> Schema(final) {
  decode.field(name, validating(inner, validations), next)
}

/// Decode an optional field with a default and validate it.
///
/// The default is used when the field is absent in the input; predicates do not
/// run against the default value.
pub fn optional_field_with(
  field_name name: name,
  default default: t,
  inner inner: decode.Decoder(t),
  validations validations: List(Predicate(t)),
  next next: fn(t) -> Schema(final),
) -> Schema(final) {
  decode.optional_field(name, default, validating(inner, validations), next)
}

/// Attach a single predicate to any decoder.
///
/// Useful when composing decoders directly (e.g. validating list elements)
/// without the field_with wrapper.
pub fn check(
  decoder decoder: decode.Decoder(t),
  predicate predicate: Predicate(t),
) -> decode.Decoder(t) {
  decode.then(decoder, fn(value) {
    case predicate(value) {
      Ok(Nil) -> decode.success(value)
      Error(message) -> decode.failure(value, message)
    }
  })
}

/// Build the final value of a schema while running cross-field validations.
///
/// Cross-field predicates receive the fully-constructed typed value and return
/// `Result(Nil, ValidationError)` so the caller controls which key the error is
/// attached to (e.g. `"confirm_password"`).
///
/// Caveat: cross-field checks run regardless of whether earlier fields failed.
/// If a per-field decode failed, the underlying `Decoder` substitutes a
/// placeholder value, and a cross-field check against placeholders may report
/// misleadingly. The two-phase pattern (`parse` followed by `valguard.list` /
/// `valguard.collect_errors`) avoids this by gating cross-field checks on
/// successful parsing.
pub fn success_with(
  value value: t,
  validations validations: List(fn(t) -> Result(Nil, ValidationError)),
) -> Schema(t) {
  // Use decode.subfield with empty path so each step's errors accumulate via
  // list.append (decode.then would short-circuit and drop later errors).
  list.fold_right(
    over: validations,
    from: decode.success(value),
    with: fn(rest, validation) {
      decode.subfield([], cross_check_decoder(value, validation), fn(_) { rest })
    },
  )
}

// --- internals ---

fn validating(
  inner: decode.Decoder(t),
  validations: List(Predicate(t)),
) -> decode.Decoder(t) {
  decode.then(inner, fn(value) {
    case run_predicates(validations, value) {
      Ok(Nil) -> decode.success(value)
      Error(message) -> decode.failure(value, message)
    }
  })
}

fn run_predicates(
  predicates: List(Predicate(t)),
  value: t,
) -> Result(Nil, String) {
  case predicates {
    [] -> Ok(Nil)
    [next, ..rest] ->
      case next(value) {
        Ok(Nil) -> run_predicates(rest, value)
        Error(message) -> Error(message)
      }
  }
}

fn cross_check_decoder(
  value: t,
  validation: fn(t) -> Result(Nil, ValidationError),
) -> decode.Decoder(t) {
  case validation(value) {
    Ok(Nil) -> decode.success(value)
    Error(ve) -> decode.failure(value, encode_ve(ve))
  }
}

fn encode_ve(ve: ValidationError) -> String {
  ve.key <> ve_marker <> ve.value
}

fn decode_error_to_validation_error(e: decode.DecodeError) -> ValidationError {
  case string.split(e.expected, on: ve_marker) {
    [key, value] -> ValidationError(key:, value:)
    _ -> {
      let key = case e.path {
        [] -> ""
        _ -> string.join(e.path, ".")
      }
      let value = case e.expected, e.found {
        "Field", "Nothing" -> "Field is required"
        _, _ -> e.expected
      }
      ValidationError(key:, value:)
    }
  }
}
