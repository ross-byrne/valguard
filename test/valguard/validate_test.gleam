import gleam/bit_array
import valguard/validate as v
import youid/uuid

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

pub fn string_length_test() {
  let message = "Value is wrong size"
  assert Ok(Nil) == v.string_length("hello", len: 5, message:)
  assert Error(message) == v.string_length("hello1", len: 5, message:)
  assert Error(message) == v.string_length("hell", len: 5, message:)
}

pub fn string_starts_with_test() {
  let value = "Hello world"
  let message = "Value is invalid"
  assert Ok(Nil) == v.string_starts_with(value, with: "Hello", message:)
  assert Ok(Nil) == v.string_starts_with(value, with: "Hello world", message:)
  assert Error(message) == v.string_starts_with(value, with: "jim", message:)
  assert Error(message) == v.string_starts_with(value, with: "hello", message:)
}

pub fn string_ends_with_test() {
  let value = "Hello world"
  let message = "Value is invalid"
  assert Ok(Nil) == v.string_ends_with(value, with: "world", message:)
  assert Ok(Nil) == v.string_ends_with(value, with: "Hello world", message:)
  assert Error(message) == v.string_ends_with(value, with: "jim", message:)
  assert Error(message) == v.string_ends_with(value, with: "World", message:)
}

pub fn string_contains_test() {
  let value = "Hello world"
  let message = "Value is invalid"
  assert Ok(Nil) == v.string_contains(value, contains: "lo wor", message:)
  assert Ok(Nil) == v.string_contains(value, contains: "Hello world", message:)
  assert Error(message) == v.string_contains(value, contains: "jim", message:)
  assert Error(message) == v.string_contains(value, contains: "World", message:)
}

// Test UUIDs generated with: https://www.uuidtools.com/
pub fn uuid_v1_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v1("", message:)
  assert Error(message) == v.uuid_v1("random text", message:)
  assert Ok(Nil) == v.uuid_v1("036da8b0-af53-11f0-aa49-cdc0883c5947", message:)

  let gen_test = uuid.v1() |> uuid.to_string
  assert Ok(Nil) == v.uuid_v1(gen_test, message:)
}

pub fn uuid_v2_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v2("", message:)
  assert Error(message) == v.uuid_v2("random text", message:)
  assert Ok(Nil) == v.uuid_v2("000003e8-af53-21f0-a200-325096b39f47", message:)
}

pub fn uuid_v3_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v3("", message:)
  assert Error(message) == v.uuid_v3("random text", message:)
  assert Ok(Nil) == v.uuid_v3("4f09f87f-8fb0-39ae-ab3f-5d2c9b6c00fb", message:)
}

pub fn uuid_v4_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v4("", message:)
  assert Error(message) == v.uuid_v4("random text", message:)
  assert Ok(Nil) == v.uuid_v4("15178939-5105-4acd-b880-9061da76ac68", message:)

  let gen_test = uuid.v4() |> uuid.to_string
  assert Ok(Nil) == v.uuid_v4(gen_test, message:)
}

pub fn uuid_v5_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v5("", message:)
  assert Error(message) == v.uuid_v5("random text", message:)
  assert Ok(Nil) == v.uuid_v5("91bfb751-9178-5512-80d3-caff6becc78e", message:)

  let assert Ok(uuid) = uuid.v5(uuid.x500_uuid(), bit_array.from_string("test"))
  let gen_test = uuid.to_string(uuid)
  assert Ok(Nil) == v.uuid_v5(gen_test, message:)
}

pub fn uuid_v7_test() {
  let message = "oops"
  assert Error(message) == v.uuid_v7("", message:)
  assert Error(message) == v.uuid_v7("random text", message:)
  assert Ok(Nil) == v.uuid_v7("019a0c55-5214-71cf-b481-dcaeb42eeb79", message:)

  let gen_test = uuid.v7() |> uuid.to_string
  assert Ok(Nil) == v.uuid_v7(gen_test, message:)
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
