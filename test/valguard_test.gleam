import gleam/option.{None, Some}
import gleeunit
import valguard.{type ValidationError, ValidationError}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn append_error_ignores_ok_values_test() {
  let result = Ok(Nil)
  let actual = valguard.append_error(result, [])
  let expected = []
  assert actual == expected
}

pub fn append_error_appends_error_value_test() {
  let error = ValidationError(key: "test", value: "test")
  let actual = valguard.append_error(Error(error), [])
  let expected = [error]
  assert actual == expected
}

pub fn append_error_appends_error_to_populated_list_test() {
  let error1 = ValidationError(key: "e1", value: "e1")
  let error2 = ValidationError(key: "e2", value: "e2")

  let actual = valguard.append_error(Error(error2), [error1])
  let expected = [error1, error2]
  assert actual == expected
}

pub fn collect_errors_returns_empty_list_when_passed_ok_values_test() {
  let result_list = [Ok(Nil), Ok(Nil)]
  let actual = valguard.collect_errors(result_list)
  let expected = []
  assert actual == expected
}

pub fn collect_errors_returns_validation_errors_test() {
  let e1 = ValidationError(key: "e1", value: "e1")
  let e2 = ValidationError(key: "e2", value: "e2")
  let result_list = [Error(e1), Ok(Nil), Error(e2)]

  let actual = valguard.collect_errors(result_list)
  let expected = [e1, e2]
  assert actual == expected
}

pub fn prepare_returns_ok_result_for_empty_list_test() {
  let actual = valguard.prepare([])
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn prepare_returns_error_result_with_validation_list_test() {
  let error_list = [
    ValidationError(key: "e1", value: "e1"),
    ValidationError(key: "e2", value: "e2"),
  ]

  let actual = valguard.prepare(error_list)
  let expected = Error(error_list)
  assert actual == expected
}

type CustomError {
  CustomError(List(ValidationError))
}

pub fn prepare_with_returns_ok_result_for_empty_list_test() {
  let actual = valguard.prepare_with([], CustomError)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn prepare_with_returns_custom_error_with_validation_list_inside_test() {
  let error_list = [
    ValidationError(key: "e1", value: "e1"),
    ValidationError(key: "e2", value: "e2"),
  ]

  let actual = valguard.prepare_with(error_list, CustomError)
  let expected = Error(CustomError(error_list))
  assert actual == expected
}

pub fn list_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Ok(Nil) },
  ]
  let actual = valguard.list("test", validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn list_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Error("e1") },
  ]
  let actual = valguard.list("test", validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn list_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn() { Ok(Nil) },
    fn() { Error("first") },
    fn() { Error("second") },
  ]
  let actual = valguard.list("test", validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}

pub fn with_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Ok(Nil) },
  ]
  let actual = valguard.with("test", "value", validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("e1") },
  ]
  let actual = valguard.with("test", "value", validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn with_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("first") },
    fn(_v) { Error("second") },
  ]
  let actual = valguard.with("test", "value", validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}

pub fn with_optional_returns_ok_when_passed_none_test() {
  let validations = [fn(_v) { Error("should not get here") }]
  let actual = valguard.with_optional("test", None, validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_optional_returns_ok_when_functions_return_ok_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Ok(Nil) },
  ]
  let actual = valguard.with_optional("test", Some("value"), validations)
  let expected = Ok(Nil)
  assert actual == expected
}

pub fn with_optional_returns_validation_errors_when_functions_return_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("e1") },
  ]
  let actual = valguard.with_optional("test", Some("value"), validations)
  let expected = Error(ValidationError(key: "test", value: "e1"))
  assert actual == expected
}

pub fn with_optional_executes_functions_lazily_and_returns_on_first_error_test() {
  let validations = [
    fn(_v) { Ok(Nil) },
    fn(_v) { Error("first") },
    fn(_v) { Error("second") },
  ]
  let actual = valguard.with_optional("test", Some("value"), validations)
  let expected = Error(ValidationError(key: "test", value: "first"))
  assert actual == expected
}
