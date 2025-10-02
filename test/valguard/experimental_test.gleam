import gleam/option.{None, Some}
import valguard/experimental as v

pub fn testing_new_with_api_test() {
  assert v.with("email", "test", [
      v.test_validation(_, None),
    ])
    == Error(v.Issue(
      key: "email",
      message: "string does not match",
      error_code: "string_not_equal",
    ))

  assert v.with("email", "test", [
      v.test_validation(_, Some("Valid email is required")),
    ])
    == Error(v.Issue(
      key: "email",
      message: "Valid email is required",
      error_code: "string_not_equal",
    ))
}
