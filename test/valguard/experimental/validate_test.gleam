import gleam/bit_array
import valguard/experimental/validate as ev
import youid/uuid

// ================== String predicates ===================

pub fn string_not_empty_test() {
  let msg = "This field is required"
  assert Ok(Nil) == ev.string_not_empty(msg)("Some Value")
  assert Error(msg) == ev.string_not_empty(msg)("")
}

pub fn string_min_test() {
  let msg = "Value is too short"
  assert Ok(Nil) == ev.string_min(5, msg)("qwerty")
  assert Ok(Nil) == ev.string_min(8, msg)("qwertyui")
  assert Error(msg) == ev.string_min(8, msg)("qwerty")
}

pub fn string_max_test() {
  let msg = "Value is too long"
  assert Ok(Nil) == ev.string_max(100, msg)("hello")
  assert Ok(Nil) == ev.string_max(5, msg)("12345")
  assert Error(msg) == ev.string_max(10, msg)("qwertyuiop[")
}

pub fn string_length_test() {
  let msg = "Value is wrong size"
  assert Ok(Nil) == ev.string_length(5, msg)("hello")
  assert Error(msg) == ev.string_length(5, msg)("hello1")
  assert Error(msg) == ev.string_length(5, msg)("hell")
}

pub fn string_starts_with_test() {
  let value = "Hello world"
  let msg = "Value is invalid"
  assert Ok(Nil) == ev.string_starts_with("Hello", msg)(value)
  assert Ok(Nil) == ev.string_starts_with("Hello world", msg)(value)
  assert Error(msg) == ev.string_starts_with("jim", msg)(value)
  assert Error(msg) == ev.string_starts_with("hello", msg)(value)
}

pub fn string_ends_with_test() {
  let value = "Hello world"
  let msg = "Value is invalid"
  assert Ok(Nil) == ev.string_ends_with("world", msg)(value)
  assert Ok(Nil) == ev.string_ends_with("Hello world", msg)(value)
  assert Error(msg) == ev.string_ends_with("jim", msg)(value)
  assert Error(msg) == ev.string_ends_with("World", msg)(value)
}

pub fn string_contains_test() {
  let value = "Hello world"
  let msg = "Value is invalid"
  assert Ok(Nil) == ev.string_contains("lo wor", msg)(value)
  assert Ok(Nil) == ev.string_contains("Hello world", msg)(value)
  assert Error(msg) == ev.string_contains("jim", msg)(value)
  assert Error(msg) == ev.string_contains("World", msg)(value)
}

// ================== Format predicates ===================

pub fn email_is_valid_test() {
  let msg = "Email address is not valid"
  assert Ok(Nil) == ev.email_is_valid(msg)("tesat@test")
  assert Ok(Nil) == ev.email_is_valid(msg)("test@test.com")
  assert Ok(Nil) == ev.email_is_valid(msg)("1@1")
  assert Ok(Nil) == ev.email_is_valid(msg)("test-2@example.com")

  assert Error(msg) == ev.email_is_valid(msg)("")
  assert Error(msg) == ev.email_is_valid(msg)("aaaaaaa")
  assert Error(msg) == ev.email_is_valid(msg)("jim@")
  assert Error(msg) == ev.email_is_valid(msg)("jim@.com")
}

pub fn date_is_valid_test() {
  let msg = "A valid date is required"
  assert Ok(Nil) == ev.date_is_valid(msg)("1970-01-01T00:00:01Z")
  assert Ok(Nil) == ev.date_is_valid(msg)("2022-01-01T13:40:00Z")
  assert Error(msg) == ev.date_is_valid(msg)("")
  assert Error(msg) == ev.date_is_valid(msg)("asdfasdf")
  assert Error(msg) == ev.date_is_valid(msg)("2010-03-03")
  assert Error(msg) == ev.date_is_valid(msg)("2010/03/03")
}

// ================== UUID predicates ===================

// Test UUIDs from: https://www.uuidtools.com/
pub fn uuid_v1_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v1(msg)("")
  assert Error(msg) == ev.uuid_v1(msg)("random text")
  assert Ok(Nil) == ev.uuid_v1(msg)("036da8b0-af53-11f0-aa49-cdc0883c5947")

  let gen = uuid.v1() |> uuid.to_string
  assert Ok(Nil) == ev.uuid_v1(msg)(gen)
}

pub fn uuid_v2_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v2(msg)("")
  assert Error(msg) == ev.uuid_v2(msg)("random text")
  assert Ok(Nil) == ev.uuid_v2(msg)("000003e8-af53-21f0-a200-325096b39f47")
}

pub fn uuid_v3_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v3(msg)("")
  assert Error(msg) == ev.uuid_v3(msg)("random text")
  assert Ok(Nil) == ev.uuid_v3(msg)("4f09f87f-8fb0-39ae-ab3f-5d2c9b6c00fb")
}

pub fn uuid_v4_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v4(msg)("")
  assert Error(msg) == ev.uuid_v4(msg)("random text")
  assert Ok(Nil) == ev.uuid_v4(msg)("15178939-5105-4acd-b880-9061da76ac68")

  let gen = uuid.v4() |> uuid.to_string
  assert Ok(Nil) == ev.uuid_v4(msg)(gen)
}

pub fn uuid_v5_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v5(msg)("")
  assert Error(msg) == ev.uuid_v5(msg)("random text")
  assert Ok(Nil) == ev.uuid_v5(msg)("91bfb751-9178-5512-80d3-caff6becc78e")

  let assert Ok(u) = uuid.v5(uuid.x500_uuid(), bit_array.from_string("test"))
  assert Ok(Nil) == ev.uuid_v5(msg)(uuid.to_string(u))
}

pub fn uuid_v7_test() {
  let msg = "oops"
  assert Error(msg) == ev.uuid_v7(msg)("")
  assert Error(msg) == ev.uuid_v7(msg)("random text")
  assert Ok(Nil) == ev.uuid_v7(msg)("019a0c55-5214-71cf-b481-dcaeb42eeb79")

  let gen = uuid.v7() |> uuid.to_string
  assert Ok(Nil) == ev.uuid_v7(msg)(gen)
}

// ================== Int predicates ===================

pub fn int_min_test() {
  let msg = "Value is too small"
  assert Ok(Nil) == ev.int_min(5, msg)(100)
  assert Ok(Nil) == ev.int_min(100, msg)(100)
  assert Error(msg) == ev.int_min(100, msg)(99)
  assert Error(msg) == ev.int_min(1, msg)(-1)
}

pub fn int_max_test() {
  let msg = "Value is too big"
  assert Ok(Nil) == ev.int_max(100, msg)(5)
  assert Ok(Nil) == ev.int_max(100, msg)(100)
  assert Error(msg) == ev.int_max(100, msg)(101)
  assert Error(msg) == ev.int_max(-1, msg)(1)
}

// ================== Float predicates ===================

pub fn float_min_test() {
  let msg = "Value is too small"
  assert Ok(Nil) == ev.float_min(5.0, msg)(100.0)
  assert Ok(Nil) == ev.float_min(100.0, msg)(100.0)
  assert Error(msg) == ev.float_min(100.0, msg)(99.0)
  assert Error(msg) == ev.float_min(1.0, msg)(-1.0)
}

pub fn float_max_test() {
  let msg = "Value is too big"
  assert Ok(Nil) == ev.float_max(100.0, msg)(5.0)
  assert Ok(Nil) == ev.float_max(100.0, msg)(100.0)
  assert Error(msg) == ev.float_max(100.0, msg)(101.0)
  assert Error(msg) == ev.float_max(-1.0, msg)(1.0)
}

// ================== Bool predicates ===================

pub fn bool_true_test() {
  let msg = "Must be accepted"
  assert Ok(Nil) == ev.bool_true(msg)(True)
  assert Error(msg) == ev.bool_true(msg)(False)
}

pub fn bool_false_test() {
  let msg = "Must be unset"
  assert Ok(Nil) == ev.bool_false(msg)(False)
  assert Error(msg) == ev.bool_false(msg)(True)
}
