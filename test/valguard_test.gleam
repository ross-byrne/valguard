import gleam/list
import gleeunit
import valguard.{type ValidationError, ValidationError}
import valguard/val

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

pub fn single_validation_test() {
  let correct = "I'm a value"
  let wrong = ""

  let result = valguard.single("correct", val.string_required(correct))
  let assert Ok(Nil) = result

  let result = valguard.single("wrong", val.string_required(wrong))
  let assert Error(ValidationError(
    key: "wrong",
    value: "This field is required",
  )) = result
}

pub fn list_using_single_value_test() {
  let value = "I am a value"
  let errors = []
  let errors =
    valguard.list("username", [
      fn() { val.string_required(value) },
      fn() { val.email_is_valid(value) },
    ])
    |> valguard.append_error(errors)

  assert list.length(errors) == 1
  let assert Ok(first) = list.first(errors)
  assert first.key == "username"
  assert first.value == "Email address is not valid"
}

pub fn list_using_multiple_values_test() {
  let username = "I am another value"
  let email = "hello@test.com"
  let errors =
    [
      valguard.list("username", [fn() { val.string_required(username) }]),
      valguard.list("email", [
        fn() { val.string_required(email) },
        fn() { val.email_is_valid(email) },
      ]),
    ]
    |> list.flat_map(fn(x) { valguard.append_error(x, []) })

  assert list.is_empty(errors)
}

pub fn with_using_single_value_test() {
  let username = "I am another value"
  let errors = []
  let errors =
    valguard.with("username", username, [
      val.string_required,
      val.email_is_valid,
    ])
    |> valguard.append_error(errors)

  assert list.length(errors) == 1
  let assert Ok(first) = list.first(errors)

  assert first.key == "username"
  assert first.value == "Email address is not valid"
}

pub fn with_using_multiple_values_test() {
  let username = "I am another value"
  let email = "hello@test.com"
  let errors =
    [
      valguard.with("username", username, [val.string_required]),
      valguard.with("email", email, [val.string_required, val.email_is_valid]),
    ]
    |> list.flat_map(fn(x) { valguard.append_error(x, []) })

  assert list.is_empty(errors)
}

pub fn with_using_manual_fn_test() {
  let username = "I am another value"
  let email = "hello@test.com"
  let errors =
    [
      valguard.with("username", username, [val.string_required]),
      valguard.with("email", email, [
        val.string_required,
        fn(x) { val.email_is_valid(x) },
      ]),
    ]
    |> list.flat_map(fn(x) { valguard.append_error(x, []) })

  assert list.is_empty(errors)
}
