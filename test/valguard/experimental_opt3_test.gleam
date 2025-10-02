import valguard/experimental_opt3 as v

pub fn testing_new_with_api_test() {
  assert v.with("email", "test", [
      v.test_validation(_, ""),
    ])
    == Error(v.ValidationError(
      key: "email",
      issue: v.Issue(message: "", error_code: "string_not_equal"),
    ))

  assert v.with("email", "test", [
      v.test_validation(_, "Valid email is required"),
    ])
    == Error(v.ValidationError(
      key: "email",
      issue: v.Issue(
        message: "Valid email is required",
        error_code: "string_not_equal",
      ),
    ))
}
