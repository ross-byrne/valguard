import valguard.{type ValidationError}
import valguard/val

type LoginParams {
  LoginParams(email: String, password: String)
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

/// Validates login params
fn validate_params(params: LoginParams) -> Result(Nil, Errors) {
  [
    valguard.with("email", params.email, [
      val.string_required,
      val.email_is_valid,
    ]),
    valguard.with("password", params.password, [val.string_required]),
  ]
  |> valguard.collect_errors
  |> valguard.prepare_with(ErrorValidatingParams)
}

pub fn login_form_validates_successfully_test() {
  let login_params = LoginParams(email: "testing@test.com", password: "qwerty")
  let result = validate_params(login_params)
  assert result == Ok(Nil)
}
