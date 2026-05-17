# Changelog

## Unreleased

- Added experimental `valguard/experimental` module: a parse + validate pipeline
  built on `gleam/dynamic/decode` that takes raw `Dynamic` input (or form data
  via `parse_form`) and returns the typed record or every accumulated error in
  one list. Existing valguard API is unchanged.
- Typed field combinators with a clear required/optional split:
  - Required: `string_field`, `int_field`, `float_field`, `bool_field` each
    take a `required_message` for missing-key or decoder-failure cases.
  - Optional: `optional_string_field`, `optional_int_field`,
    `optional_float_field`, `optional_bool_field` return `Option(t)`; missing
    key, empty string `""`, and JSON null all produce `None`.
  - Smart decoders accept both JSON-native and form-string inputs (e.g.
    `int_field` parses both `42` and `"42"`).
  - Escape hatches: `field_with` (with explicit placeholder) and
    `optional_field_with`.
- Added `valguard/experimental/validate` module with curried predicates:
  `string_not_empty`, `string_min`/`max`/`length`/`starts_with`/`ends_with`/
  `contains`, `email_is_valid`, `date_is_valid`, `uuid_v1`–`v7`,
  `int_min`/`max`, `float_min`/`max`, `bool_true`/`false`.
- Updated dependencies

## v0.7.1

- Updated dependencies

## v0.7.0

- Added validation functions for UUID v1, v2, v3, v4, v5, and v7

## v0.6.0

- **Breaking:** Removed `valguard/val` module
- **Breaking:** Moved validation functions from `valguard` to `valguard/validate`
- Added new string validation functions

## v0.5.0

- Validation functions in `valguard/val` have been deprecated in favour of functions in `valguard`
- Validation functions in `valguard` module now take both the value they are validating and an error message
to return if the validation fails

## v0.4.1

- Fixed validation message for `date_is_valid` referencing time instead of date

## v0.4.0

- Added `with_optional` function for handling validation of optional values.
Returns early with `Ok(Nil)` if value is `None`.

## v0.3.0

- Removed deprecated functions `single` and `wrap_result`

## v0.2.1

- Updated unit tests
- Added integration tests
- Deprecated function `wrap_result`

## v0.2.0

- Deprecated the function `single` in favour of `with`
- Added `float_required` function
- Updated `int_required` to access negative numbers

## v0.1.0

- The initial release
