import valguard/experimental as v

pub fn testing_new_with_api_test() {
  assert v.with("email", "test", [
      v.test_validation(_, ""),
    ])
    == Error(v.Issue(key: "email", message: "", error_code: "string_not_equal"))

  assert v.with("email", "test", [
      v.test_validation(_, "Valid email is required"),
    ])
    == Error(v.Issue(
      key: "email",
      message: "Valid email is required",
      error_code: "string_not_equal",
    ))
}
