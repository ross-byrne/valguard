import gleam/option.{None, Some}
import gleeunit
import valguard.{type ValidationError, ValidationError} as v

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn append_error_ignores_ok_values_test() {
  let result = Ok(Nil)
  let actual = v.append_error(result, [])
  let expected = []
  assert actual == expected
}

pub fn append_error_appends_error_value_test() {
  let error = ValidationError(key: "test", value: "test")
  let actual = v.append_error(Error(error), [])
  let expected = [error]
  assert actual == expected
}

pub fn append_error_appends_error_to_populated_list_test() {
  let error1 = ValidationError(key: "e1", value: "e1")
  let error2 = ValidationError(key: "e2", value: "e2")

  let actual = v.append_error(Error(error2), [error1])
  let expected = [error1, error2]
  assert actual == expected
}

pub fn collect_errors_returns_empty_list_when_passed_ok_values_test() {
  let result_list = [Ok(Nil), Ok(Nil)]
  let actual = v.collect_errors(result_list)
  let expected = []
  assert actual == expected
}

pub fn collect_errors_returns_validation_errors_test() {
  let e1 = ValidationError(key: "e1", value: "e1")
  let e2 = ValidationError(key: "e2", value: "e2")
  let result_list = [Error(e1), Ok(Nil), Error(e2)]

  let actual = v.collect_errors(result_list)
  let expected = [e1, e2]
  assert actual == expected
}

pub fn prepare_returns_ok_result_for_empty_list_test() {
  let actual = v.prepare([])
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn prepare_returns_error_result_with_validation_list_test() {
  let error_list = [
    ValidationError(key: "e1", value: "e1"),
    ValidationError(key: "e2", value: "e2"),
  ]

  let actual = v.prepare(error_list)
  let expected = Error(error_list)
  assert actual == expected
}

type CustomError {
  CustomError(List(ValidationError))
}

pub fn prepare_with_returns_ok_result_for_empty_list_test() {
  let actual = v.prepare_with([], CustomError)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn prepare_with_returns_custom_error_with_validation_list_inside_test() {
  let error_list = [
    ValidationError(key: "e1", value: "e1"),
    ValidationError(key: "e2", value: "e2"),
  ]

  let actual = v.prepare_with(error_list, CustomError)
  let expected = Error(CustomError(error_list))
  assert actual == expected
}

pub fn list_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Ok(Nil) },
  ]
  let actual = v.list("test", validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn list_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Error("e1") },
  ]
  let actual = v.list("test", validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn list_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Error("first") },
    fn() { Error("second") },
  ]
  let actual = v.list("test", validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}

pub fn with_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Ok(Nil) },
  ]
  let actual = v.with("test", "value", validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("e1") },
  ]
  let actual = v.with("test", "value", validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn with_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("first") },
    fn(_v) { Error("second") },
  ]
  let actual = v.with("test", "value", validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}

pub fn with_optional_returns_ok_when_passed_none_test() {
  let validations = [fn(_v) { Error("should not get here") }]
  let actual = v.with_optional("test", None, validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_optional_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Ok(Nil) },
  ]
  let actual = v.with_optional("test", Some("value"), validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_optional_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("e1") },
  ]
  let actual = v.with_optional("test", Some("value"), validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn with_optional_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("first") },
    fn(_v) { Error("second") },
  ]
  let actual = v.with_optional("test", Some("value"), validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}

pub fn int_require_test() {
  let message = "This field is required"
  assert Ok(Nil) == v.int_required(100, message)
  assert Ok(Nil) == v.int_required(1, message)
  assert Ok(Nil) == v.int_required(-5, message)
  assert Error(message) == v.int_required(0, message)
}

pub fn int_min_test() {
  let message = "Value is too small"
  assert Ok(Nil) == v.int_min(100, min: 5, message:)
  assert Ok(Nil) == v.int_min(100, min: 100, message:)
  assert Error(message) == v.int_min(99, min: 100, message:)
  assert Error(message) == v.int_min(-1, min: 1, message:)
}

pub fn int_max_test() {
  let message = "Value is too big"
  assert Ok(Nil) == v.int_max(5, max: 100, message:)
  assert Ok(Nil) == v.int_max(100, max: 100, message:)
  assert Error(message) == v.int_max(101, max: 100, message:)
  assert Error(message) == v.int_max(1, max: -1, message:)
}

pub fn float_require_test() {
  let message = "This field is required"
  assert Ok(Nil) == v.float_required(100.0, message:)
  assert Ok(Nil) == v.float_required(1.0, message:)
  assert Ok(Nil) == v.float_required(-5.0001, message:)
  assert Ok(Nil) == v.float_required(0.0000000000001, message:)
  assert Ok(Nil) == v.float_required(-0.0000000000001, message:)
  assert Error(message) == v.float_required(0.0, message:)
}

pub fn float_min_test() {
  let message = "Value is too small"
  assert Ok(Nil) == v.float_min(100.0, min: 5.0, message:)
  assert Ok(Nil) == v.float_min(100.0, min: 100.0, message:)
  assert Error(message) == v.float_min(99.0, min: 100.0, message:)
  assert Error(message) == v.float_min(-1.0, min: 1.0, message:)
}

pub fn float_max_test() {
  let message = "Value is too big"
  assert Ok(Nil) == v.float_max(5.0, max: 100.0, message:)
  assert Ok(Nil) == v.float_max(100.0, max: 100.0, message:)
  assert Error(message) == v.float_max(101.0, max: 100.0, message:)
  assert Error(message) == v.float_max(1.0, max: -1.0, message:)
}

pub fn string_required_test() {
  let message = "This field is required"
  assert Ok(Nil) == v.string_required("Some Value", message:)
  assert Error(message) == v.string_required("", message:)
}

pub fn string_min_test() {
  let message = "Value is too small"
  assert Ok(Nil) == v.string_min("qwerty", min: 5, message:)
  assert Ok(Nil) == v.string_min("qwertyui", min: 8, message:)
  assert Error(message) == v.string_min("qwerty", min: 8, message:)
}

pub fn string_max_test() {
  let message = "Value is too big"
  assert Ok(Nil) == v.string_max("hello", max: 100, message:)
  assert Ok(Nil) == v.string_max("12345", max: 5, message:)
  assert Error(message) == v.string_max("qwertyuiop[", max: 10, message:)
}

pub fn email_is_valid_test() {
  let message = "Email address is not valid"
  assert Ok(Nil) == v.email_is_valid("tesat@test", message:)
  assert Ok(Nil) == v.email_is_valid("test@test.com", message:)
  assert Ok(Nil) == v.email_is_valid("1@1", message:)
  assert Ok(Nil) == v.email_is_valid("test-2@example.com", message:)
  assert Ok(Nil) == v.email_is_valid("john@do.com", message:)

  assert Error(message) == v.email_is_valid("", message:)
  assert Error(message) == v.email_is_valid("aaaaaaa", message:)
  assert Error(message) == v.email_is_valid("1112123123", message:)
  assert Error(message) == v.email_is_valid("jim@", message:)
  assert Error(message) == v.email_is_valid("ji  m@", message:)
  assert Error(message) == v.email_is_valid("jim@.com", message:)
  assert Error(message) == v.email_is_valid("jim@.", message:)
}

pub fn date_is_valid_test() {
  let message = "A valid date is required"
  assert Ok(Nil) == v.date_is_valid("1970-01-01T00:00:01Z", message:)
  assert Ok(Nil) == v.date_is_valid("2022-01-01T13:40:00Z", message:)
  assert Error(message) == v.date_is_valid("", message:)
  assert Error(message) == v.date_is_valid("asdfasdf", message:)
  assert Error(message) == v.date_is_valid("2010-03-03", message:)
  assert Error(message) == v.date_is_valid("2010/03/03", message:)
}
