import valguard/val

pub fn require_int_test() {
  assert Ok(Nil) == val.int_required(100)
  assert Ok(Nil) == val.int_required(1)
  assert Error("This field is required") == val.int_required(0)
}

pub fn int_min_test() {
  assert Ok(Nil) == val.int_min(100, min: 5)
  assert Ok(Nil) == val.int_min(100, min: 100)
  assert Error("Value must be a minimum of 100") == val.int_min(99, min: 100)
  assert Error("Value must be a minimum of 1") == val.int_min(-1, min: 1)
}

pub fn int_max_test() {
  assert Ok(Nil) == val.int_max(5, max: 100)
  assert Ok(Nil) == val.int_max(100, max: 100)
  assert Error("Value must be a maximum of 100") == val.int_max(101, max: 100)
  assert Error("Value must be a maximum of -1") == val.int_max(1, max: -1)
}

pub fn float_min_test() {
  assert Ok(Nil) == val.float_min(100.0, min: 5.0)
  assert Ok(Nil) == val.float_min(100.0, min: 100.0)
  assert Error("Value must be a minimum of 100.0")
    == val.float_min(99.0, min: 100.0)
  assert Error("Value must be a minimum of 1.0")
    == val.float_min(-1.0, min: 1.0)
}

pub fn float_max_test() {
  assert Ok(Nil) == val.float_max(5.0, max: 100.0)
  assert Ok(Nil) == val.float_max(100.0, max: 100.0)
  assert Error("Value must be a maximum of 100.0")
    == val.float_max(101.0, max: 100.0)
  assert Error("Value must be a maximum of -1.0")
    == val.float_max(1.0, max: -1.0)
}

pub fn string_required_test() {
  assert Ok(Nil) == val.string_required("Some Value")
  assert Error("This field is required") == val.string_required("")
}

pub fn string_min_test() {
  assert Ok(Nil) == val.string_min("qwerty", min: 5)
  assert Ok(Nil) == val.string_min("qwertyui", min: 8)
  assert Error("Value must be a minimum of 8 characters")
    == val.string_min("qwerty", min: 8)
}

pub fn string_max_test() {
  assert Ok(Nil) == val.string_max("hello", max: 100)
  assert Ok(Nil) == val.string_max("12345", max: 5)
  assert Error("Value must be a maximum of 10 characters")
    == val.string_max("qwertyuiop[", max: 10)
}

pub fn email_is_valid_test() {
  assert Ok(Nil) == val.email_is_valid("test@test")
  assert Ok(Nil) == val.email_is_valid("test@test.com")
  assert Ok(Nil) == val.email_is_valid("1@1")
  assert Ok(Nil) == val.email_is_valid("test-2@example.com")
  assert Ok(Nil) == val.email_is_valid("john@do.com")

  let msg = "Email address is not valid"
  assert Error(msg) == val.email_is_valid("")
  assert Error(msg) == val.email_is_valid("aaaaaaa")
  assert Error(msg) == val.email_is_valid("1112123123")
  assert Error(msg) == val.email_is_valid("jim@")
  assert Error(msg) == val.email_is_valid("ji  m@")
  assert Error(msg) == val.email_is_valid("jim@.com")
  assert Error(msg) == val.email_is_valid("jim@.")
}

pub fn date_is_valid_test() {
  assert Ok(Nil) == val.date_is_valid("1970-01-01T00:00:01Z")
  assert Ok(Nil) == val.date_is_valid("2022-01-01T13:40:00Z")
  assert Error("A valid time is required") == val.date_is_valid("")
  assert Error("A valid time is required") == val.date_is_valid("asdfasdf")
  assert Error("A valid time is required") == val.date_is_valid("2010-03-03")
  assert Error("A valid time is required") == val.date_is_valid("2010/03/03")
}
