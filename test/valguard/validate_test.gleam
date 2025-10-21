import valguard/validate as v

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
