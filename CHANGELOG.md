# Changelog

## Unreleased

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
