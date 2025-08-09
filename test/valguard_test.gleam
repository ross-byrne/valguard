import gleam/list
import gleeunit
import valguard.{ValidationError}
import valguard/val

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn append_error_test() {
  let value = "I am a value"
  let value2 = ""
  let errors =
    valguard.with("username", value, [val.required])
    |> valguard.append_error([])

  // list should be empty
  assert list.is_empty(errors) == True

  let errors =
    valguard.with("username", value2, [val.required])
    |> valguard.append_error(errors)

  assert list.length(errors) == 1
  let assert Ok(first) = list.first(errors)
  assert first.key == "username"
  assert first.value == "This field is required"
}

pub fn collect_errors_returns_empty_list_test() {
  let username = "I am value"
  let email = "hello@test.com"
  let errors =
    [
      valguard.with("username", username, [val.required]),
      valguard.with("email", email, [val.required, val.email_is_valid]),
    ]
    |> valguard.collect_errors

  assert list.is_empty(errors)
}

pub fn collect_errors_returns_validation_errors_test() {
  let username = "I am value"
  let email = "notanemail"
  let password = ""
  let errors =
    [
      valguard.with("username", username, [val.required]),
      valguard.with("email", email, [val.required, val.email_is_valid]),
      valguard.with("password", password, [val.required]),
    ]
    |> valguard.collect_errors

  // check error values are correct
  assert [
      ValidationError(key: "email", value: "Email address is not valid"),
      ValidationError(key: "password", value: "This field is required"),
    ]
    == errors
}

pub fn single_validation_test() {
  let correct = "I'm a value"
  let wrong = ""

  let result = valguard.single("correct", val.required(correct))
  let assert Ok(Nil) = result

  let result = valguard.single("wrong", val.required(wrong))
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
      fn() { val.required(value) },
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
      valguard.list("username", [fn() { val.required(username) }]),
      valguard.list("email", [
        fn() { val.required(email) },
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
    valguard.with("username", username, [val.required, val.email_is_valid])
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
      valguard.with("username", username, [val.required]),
      valguard.with("email", email, [val.required, val.email_is_valid]),
    ]
    |> list.flat_map(fn(x) { valguard.append_error(x, []) })

  assert list.is_empty(errors)
}

pub fn with_using_manual_fn_test() {
  let username = "I am another value"
  let email = "hello@test.com"
  let errors =
    [
      valguard.with("username", username, [val.required]),
      valguard.with("email", email, [
        val.required,
        fn(x) { val.email_is_valid(x) },
      ]),
    ]
    |> list.flat_map(fn(x) { valguard.append_error(x, []) })

  assert list.is_empty(errors)
}
