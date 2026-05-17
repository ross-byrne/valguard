//// Experimental: parse + validate pipeline built on top of `gleam/dynamic/decode`.
////
//// A schema (`Schema(t)`, an alias for `decode.Decoder(t)`) parses raw
//// `Dynamic` input AND runs per-field validations in a single pass,
//// accumulating all errors. Pass the schema to `parse(schema, data)` or
//// `parse_form(schema, values)` to get back either the typed record or a
//// `List(ValidationError)`.
////
//// Cross-field validation (e.g. "passwords must match") goes alongside the
//// schema as the third argument — see `parse` / `parse_form` / `cross`.
//// Cross-field checks run only when per-field validation passes, so they
//// never see placeholder values from a failed earlier decode.
////
//// This module is experimental — the API may change before being promoted into
//// the main `valguard` module.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import valguard.{type ValidationError, ValidationError}

// Sentinel used to round-trip ValidationError key/value pairs through
// DecodeError.expected (Decoder is opaque, so we can't emit a custom error
// structure directly). Decoded back in decode_error_to_validation_error.
const ve_marker = "\u{0000}__valguard_ve__\u{0000}"

/// A parse + validate schema. Just an alias for `decode.Decoder(t)` — declare
/// schemas as functions returning a `Schema(t)` and pass them to `parse`.
pub type Schema(t) =
  decode.Decoder(t)

/// A field-level validation predicate. Returns `Ok(Nil)` if the value passes,
/// or `Error(message)` to attach `message` to the field's `ValidationError`.
pub type Predicate(t) =
  fn(t) -> Result(Nil, String)

/// A post-parse validation. Receives the fully-constructed typed value and
/// returns either `Ok(Nil)` or `Error(ValidationError)` keyed to whichever
/// field the error belongs to. Built via `validate`.
pub type Validation(t) =
  fn(t) -> Result(Nil, ValidationError)

// ================== Entry points ===================

/// Apply a schema to raw `Dynamic` input. Cross-field validators run after
/// per-field validation succeeds — pass `[]` if you don't have any.
///
/// Returns the typed value on success, or every accumulated parse and
/// per-field validation error in one list.
pub fn parse(
  schema schema: Schema(t),
  data data: decode.Dynamic,
  validations validations: List(Validation(t)),
) -> Result(t, List(ValidationError)) {
  case decode.run(data, schema) {
    Ok(value) -> apply_validations(value, validations)
    Error(errors) -> Error(list.map(errors, decode_error_to_validation_error))
  }
}

/// Apply a schema to a list of form key/value pairs (as produced by Wisp's
/// `FormData.values`). Cross-field validators run after per-field validation
/// succeeds — pass `[]` if you don't have any.
pub fn parse_form(
  schema schema: Schema(t),
  values values: List(#(String, String)),
  validations validations: List(Validation(t)),
) -> Result(t, List(ValidationError)) {
  let entries =
    list.map(values, fn(pair) {
      let #(key, value) = pair
      #(dynamic.string(key), dynamic.string(value))
    })
  parse(schema, dynamic.properties(entries), validations)
}

/// Build a post-parse validator that emits a `ValidationError` keyed to
/// `field_name` when `check` returns `Error(message)`.
pub fn validate(
  field_name field_name: String,
  check check: fn(t) -> Result(Nil, String),
) -> Validation(t) {
  fn(value) {
    case check(value) {
      Ok(Nil) -> Ok(Nil)
      Error(message) -> Error(ValidationError(key: field_name, value: message))
    }
  }
}

// ================== Required typed field combinators ===================

/// Decode a required string field.
///
/// Missing key, empty string `""`, or any decoder failure → `required_message`.
/// Required strings always reject empty input — for "may be empty" semantics
/// use `optional_string_field` instead. Predicates run on non-empty values.
pub fn string_field(
  field_name name: String,
  required_message required_message: String,
  validations validations: List(Predicate(String)),
  next next: fn(String) -> Schema(final),
) -> Schema(final) {
  // Prepend an empty-check predicate that fires with required_message. This
  // unifies "missing key" and "empty value" under one message — the common
  // case in form validation.
  let non_empty_check = fn(value: String) {
    case string.is_empty(value) {
      True -> Error(required_message)
      False -> Ok(Nil)
    }
  }
  field_with(
    name,
    decode.string,
    "",
    required_message,
    [non_empty_check, ..validations],
    next,
  )
}

/// Decode a required int field.
///
/// Accepts both JSON-native ints (`42`) and form-string ints (`"42"`).
/// Missing key OR any decoder failure → `required_message`.
pub fn int_field(
  field_name name: String,
  required_message required_message: String,
  validations validations: List(Predicate(Int)),
  next next: fn(Int) -> Schema(final),
) -> Schema(final) {
  field_with(name, smart_int_decoder(), 0, required_message, validations, next)
}

/// Decode a required float field.
///
/// Accepts both JSON-native floats (`3.14`) and form-string floats (`"3.14"`).
/// Missing key OR any decoder failure → `required_message`.
pub fn float_field(
  field_name name: String,
  required_message required_message: String,
  validations validations: List(Predicate(Float)),
  next next: fn(Float) -> Schema(final),
) -> Schema(final) {
  field_with(
    name,
    smart_float_decoder(),
    0.0,
    required_message,
    validations,
    next,
  )
}

/// Decode a required bool field.
///
/// Accepts both JSON-native bools (`true`/`false`) and form-string bools
/// (`"true"`/`"false"`/`"on"`/`"off"`/`"1"`/`"0"`).
/// Missing key OR any decoder failure → `required_message`.
pub fn bool_field(
  field_name name: String,
  required_message required_message: String,
  validations validations: List(Predicate(Bool)),
  next next: fn(Bool) -> Schema(final),
) -> Schema(final) {
  field_with(
    name,
    smart_bool_decoder(),
    False,
    required_message,
    validations,
    next,
  )
}

// ================== Optional typed field combinators ===================

/// Decode an optional string field.
///
/// Missing key OR empty string `""` OR JSON null → `None` (no errors,
/// predicates do not run). Present non-empty string → `Some(value)` with
/// predicates run on the value. JSON non-string value → type error
/// `"Must be a string"`.
pub fn optional_string_field(
  field_name name: String,
  validations validations: List(Predicate(String)),
  next next: fn(Option(String)) -> Schema(final),
) -> Schema(final) {
  optional_field_internal(
    name,
    decode.string,
    "Must be a string",
    validations,
    next,
  )
}

/// Decode an optional int field.
///
/// Missing key OR empty string `""` OR JSON null → `None`. Present and
/// parseable → `Some(value)`. Present and non-empty but not a valid int →
/// type error `"Must be a valid integer"`.
pub fn optional_int_field(
  field_name name: String,
  validations validations: List(Predicate(Int)),
  next next: fn(Option(Int)) -> Schema(final),
) -> Schema(final) {
  optional_field_internal(
    name,
    smart_int_decoder(),
    "Must be a valid integer",
    validations,
    next,
  )
}

/// Decode an optional float field.
///
/// Missing key OR empty string `""` OR JSON null → `None`. Present and
/// parseable → `Some(value)`. Present and non-empty but not a valid float →
/// type error `"Must be a valid number"`.
pub fn optional_float_field(
  field_name name: String,
  validations validations: List(Predicate(Float)),
  next next: fn(Option(Float)) -> Schema(final),
) -> Schema(final) {
  optional_field_internal(
    name,
    smart_float_decoder(),
    "Must be a valid number",
    validations,
    next,
  )
}

/// Decode an optional bool field.
///
/// Missing key OR empty string `""` OR JSON null → `None`. Present and
/// parseable → `Some(value)`. Present and non-empty but not a valid bool →
/// type error `"Must be true or false"`.
pub fn optional_bool_field(
  field_name name: String,
  validations validations: List(Predicate(Bool)),
  next next: fn(Option(Bool)) -> Schema(final),
) -> Schema(final) {
  optional_field_internal(
    name,
    smart_bool_decoder(),
    "Must be true or false",
    validations,
    next,
  )
}

// ================== Generic escape hatches ===================

/// Generic required field combinator for custom decoders.
///
/// `placeholder` is a value of type `t` used internally to keep the schema
/// chain going when the field is missing or the decoder fails — it is never
/// returned to the caller, so the choice has no semantic effect. Use a
/// cheap throwaway value (e.g. `""`, `0`, `0.0`, `False`, or any record
/// default). For the four primitive types, prefer the typed combinators
/// (`string_field`, `int_field`, etc.) which bake in a sensible placeholder.
///
/// Missing key OR any decoder failure → `required_message`.
pub fn field_with(
  field_name name: String,
  inner inner: decode.Decoder(t),
  placeholder placeholder: t,
  required_message required_message: String,
  validations validations: List(Predicate(t)),
  next next: fn(t) -> Schema(final),
) -> Schema(final) {
  // Wrap inner: succeed with Ok(value), or fall back to Error(Nil) on any failure
  let wrapped: decode.Decoder(Result(t, Nil)) =
    decode.one_of(decode.map(inner, Ok), [decode.success(Error(Nil))])

  use raw <- decode.optional_field(name, Error(Nil), wrapped)

  case raw {
    Error(Nil) ->
      emit_field_error_and_continue(name, required_message, fn() {
        next(placeholder)
      })
    Ok(value) ->
      case run_predicates(validations, value) {
        Ok(Nil) -> next(value)
        Error(message) ->
          emit_field_error_and_continue(name, message, fn() { next(value) })
      }
  }
}

/// Generic optional field combinator for custom decoders.
///
/// Missing key OR empty string `""` OR JSON null → `None`. Present and
/// decodes successfully → `Some(value)` with predicates run on the value.
/// Present non-absent but decoder fails → emits `"Invalid value"` as a
/// fallback message (the stdlib decoder's raw error message — e.g. `"Int"`,
/// `"String"` — is rarely user-friendly, so we substitute a generic one).
/// For typed primitives, prefer the typed `optional_*_field` variants
/// which provide friendlier per-type messages (`"Must be a valid integer"`,
/// etc.).
pub fn optional_field_with(
  field_name name: String,
  inner inner: decode.Decoder(t),
  validations validations: List(Predicate(t)),
  next next: fn(Option(t)) -> Schema(final),
) -> Schema(final) {
  optional_field_internal(name, inner, "Invalid value", validations, next)
}

// ================== Schema terminators ===================

/// Finalise a schema with a typed value. Re-export of `decode.success` so
/// users don't need to import `gleam/dynamic/decode` directly.
pub fn success(value: t) -> Schema(t) {
  decode.success(value)
}

// ================== Validation helpers ===================

/// Attach a single predicate to any decoder.
///
/// Useful when composing decoders directly (e.g. validating list elements)
/// without a field_with wrapper.
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

// ================== Internals: post-parse validation ===================

fn apply_validations(
  value: t,
  validations: List(Validation(t)),
) -> Result(t, List(ValidationError)) {
  let errors =
    list.filter_map(validations, fn(check) {
      case check(value) {
        Ok(Nil) -> Error(Nil)
        Error(ve) -> Ok(ve)
      }
    })
  case errors {
    [] -> Ok(value)
    _ -> Error(errors)
  }
}

// ================== Internals: optional field implementation ===================

fn optional_field_internal(
  field_name: String,
  inner: decode.Decoder(t),
  type_error_message: String,
  validations: List(Predicate(t)),
  next: fn(Option(t)) -> Schema(final),
) -> Schema(final) {
  // Get raw Dynamic at the field; default dynamic.nil() means missing key
  use raw <- decode.optional_field(field_name, dynamic.nil(), decode.dynamic)

  case is_absent(raw) {
    True -> next(None)
    False ->
      case decode.run(raw, inner) {
        Ok(value) ->
          case run_predicates(validations, value) {
            Ok(Nil) -> next(Some(value))
            Error(message) ->
              emit_field_error_and_continue(field_name, message, fn() {
                next(Some(value))
              })
          }
        Error(_) ->
          emit_field_error_and_continue(field_name, type_error_message, fn() {
            next(None)
          })
      }
  }
}

/// True if the Dynamic represents an "absent" value: JSON null / Erlang nil /
/// JS undefined, OR an empty string (HTML form idiom for "user didn't fill in").
///
/// The empty-string coercion is intentional, not a bug — HTML form inputs
/// ALWAYS submit their key, with `""` as the value when the user typed
/// nothing. For optional fields, that means "absent" and "empty string" are
/// the same thing in form contexts. For JSON APIs that genuinely want to
/// distinguish `{"email": null}` from `{"email": ""}`, use `field_with`
/// with `decode.optional(decode.string)` as the escape hatch instead.
fn is_absent(raw: decode.Dynamic) -> Bool {
  case dynamic.classify(raw) {
    "Nil" -> True
    _ ->
      case decode.run(raw, decode.string) {
        Ok("") -> True
        _ -> False
      }
  }
}

// ================== Internals: smart decoders ===================

fn smart_int_decoder() -> decode.Decoder(Int) {
  decode.one_of(decode.int, [form_int_parser()])
}

fn smart_float_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [form_float_parser()])
}

fn smart_bool_decoder() -> decode.Decoder(Bool) {
  decode.one_of(decode.bool, [form_bool_parser()])
}

fn form_int_parser() -> decode.Decoder(Int) {
  use s <- decode.then(decode.string)
  case int.parse(s) {
    Ok(n) -> decode.success(n)
    Error(_) -> decode.failure(0, "Int")
  }
}

fn form_float_parser() -> decode.Decoder(Float) {
  use s <- decode.then(decode.string)
  case float.parse(s) {
    Ok(n) -> decode.success(n)
    Error(_) -> decode.failure(0.0, "Float")
  }
}

fn form_bool_parser() -> decode.Decoder(Bool) {
  use s <- decode.then(decode.string)
  case s {
    "true" | "on" | "1" -> decode.success(True)
    "false" | "off" | "0" -> decode.success(False)
    _ -> decode.failure(False, "Bool")
  }
}

// ================== Internals: predicates and error encoding ===================

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

fn emit_field_error_and_continue(
  field_name: String,
  message: String,
  next: fn() -> Schema(final),
) -> Schema(final) {
  let encoded = encode_ve(ValidationError(key: field_name, value: message))
  decode.subfield([], decode.failure(Nil, encoded), fn(_) { next() })
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
