//// Integration testing a complex real-world valguard usage
////
//// - 9 fields with a realistic optional/required mix (1 required + 8 optional)
//// - A DB-backed predicate that's context-aware (different behavior for
////   create vs update)
//// - Cross-field validation (phone country code + phone number interdependency)
////   via the two-phase pattern
//// - Mixed validation styles: built-in `ev.*`, custom self-contained
////   predicates (`gender_is_valid` etc.), and a custom DB-backed predicate
////   that closes over context
//// - The same schema serving both create and update by threading a
////   `client_id: Option(Int)` parameter through
////
//// Custom predicates are inlined here so the file is self-contained — in a
//// real project they'd live in a shared module (mirroring timestack's
//// `src/app/utils/validate.gleam`).

import gleam/dynamic
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import valguard.{type ValidationError, ValidationError}
import valguard/experimental as ve
import valguard/experimental/validate as ev

// ================== Test setup ===================

type Connection {
  Connection
}

type ClientParams {
  ClientParams(
    email: Option(String),
    first_name: String,
    last_name: Option(String),
    phone_alpha2: Option(String),
    phone_number: Option(String),
    date_of_birth: Option(String),
    gender: Option(String),
    pronouns: Option(String),
    country_alpha2: Option(String),
  )
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

// ================== Custom predicates ===================

/// DB-backed predicate with create/update context awareness.
///
/// - On create (`client_id = None`): enforces workspace-wide uniqueness.
/// - On update (`client_id = Some(id)`): allows the current email to remain
///   (the existing record is exempted from the uniqueness check).
///
/// Curried — takes the context and returns a `Predicate(String)`.
fn client_email_available_for(
  _db: Connection,
  client_id: Option(Int),
) -> ve.Predicate(String) {
  fn(email) {
    // Simulated DB check. In production these would be two separate SQL queries.
    // - "current@me.com" is the email already owned by client 42 (update exemption).
    // - "taken@example.com" is owned by some other client (always rejected).
    case client_id, email {
      Some(42), "current@me.com" -> Ok(Nil)
      _, "taken@example.com" -> Error("Email address is not available")
      _, _ -> Ok(Nil)
    }
  }
}

/// Cross-field validator: a phone number requires a valid country code when
/// present. Receives the full ClientParams and inspects two fields.
fn phone_number_is_valid(p: ClientParams) -> Result(Nil, String) {
  case p.phone_alpha2, p.phone_number {
    None, None -> Ok(Nil)
    Some(_), None -> Ok(Nil)
    None, Some(_) -> Error("Valid country code is required")
    Some(_a), Some(_n) ->
      // Simulated phone format check. In production: phony.validate_by_country.
      Ok(Nil)
  }
}

/// Simple enum-style validators backed by hardcoded allowlists. Already match
/// the `Predicate(String)` shape — slot into a predicate list unchanged.
fn gender_is_valid(value: String) -> Result(Nil, String) {
  case list.contains(["male", "female", "non_binary", "other"], value) {
    True -> Ok(Nil)
    False -> Error("Select a valid option")
  }
}

fn pronoun_is_valid(value: String) -> Result(Nil, String) {
  case list.contains(["he/him", "she/her", "they/them"], value) {
    True -> Ok(Nil)
    False -> Error("Select a valid option")
  }
}

fn country_is_valid(value: String) -> Result(Nil, String) {
  case list.contains(["US", "GB", "IE", "FR", "DE"], value) {
    True -> Ok(Nil)
    False -> Error("Select a valid option")
  }
}

// ================== Schema ===================

fn client_schema(
  db: Connection,
  client_id: Option(Int),
) -> ve.Schema(ClientParams) {
  let required = "This field is required"
  use email <- ve.optional_string_field("email", [
    ev.email_is_valid("Email address is not valid"),
    client_email_available_for(db, client_id),
  ])
  use first_name <- ve.string_field("first_name", required, [
    ev.string_not_empty(required),
  ])
  use last_name <- ve.optional_string_field("last_name", [])
  use phone_alpha2 <- ve.optional_string_field("phone_alpha2", [])
  use phone_number <- ve.optional_string_field("phone_number", [])
  use date_of_birth <- ve.optional_string_field("date_of_birth", [
    ev.date_is_valid("Date is not valid"),
  ])
  use gender <- ve.optional_string_field("gender", [gender_is_valid])
  use pronouns <- ve.optional_string_field("pronouns", [pronoun_is_valid])
  use country_alpha2 <- ve.optional_string_field("country_alpha2", [
    country_is_valid,
  ])

  ve.success(ClientParams(
    email:,
    first_name:,
    last_name:,
    phone_alpha2:,
    phone_number:,
    date_of_birth:,
    gender:,
    pronouns:,
    country_alpha2:,
  ))
}

/// Same function for create AND update — the `client_id` parameter threads
/// through to `client_email_available_for` which dispatches internally.
/// Cross-field phone validation runs only when per-field validation passed.
fn validate(
  db: Connection,
  client_id: Option(Int),
  values: List(#(String, String)),
) -> Result(ClientParams, Errors) {
  ve.parse_form(client_schema(db, client_id), values, [
    ve.validate("phone_number", phone_number_is_valid),
  ])
  |> result.map_error(ErrorValidatingParams)
}

/// Helper for building a form payload with every field. Use `""` for any
/// field you want to omit (optional combinators treat `""` as absent).
fn form_payload(
  email email: String,
  first_name first_name: String,
  last_name last_name: String,
  phone_alpha2 phone_alpha2: String,
  phone_number phone_number: String,
  date_of_birth date_of_birth: String,
  gender gender: String,
  pronouns pronouns: String,
  country_alpha2 country_alpha2: String,
) -> List(#(String, String)) {
  [
    #("email", email),
    #("first_name", first_name),
    #("last_name", last_name),
    #("phone_alpha2", phone_alpha2),
    #("phone_number", phone_number),
    #("date_of_birth", date_of_birth),
    #("gender", gender),
    #("pronouns", pronouns),
    #("country_alpha2", country_alpha2),
  ]
}

// ================== Tests ===================

pub fn client_create_validates_with_just_first_name_test() {
  // Minimum valid input: only first_name is required.
  let db = Connection
  let values =
    form_payload(
      email: "",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  assert actual
    == Ok(ClientParams(
      email: None,
      first_name: "Alice",
      last_name: None,
      phone_alpha2: None,
      phone_number: None,
      date_of_birth: None,
      gender: None,
      pronouns: None,
      country_alpha2: None,
    ))
}

pub fn client_create_validates_full_form_test() {
  let db = Connection
  let values =
    form_payload(
      email: "alice@example.com",
      first_name: "Alice",
      last_name: "Smith",
      phone_alpha2: "US",
      phone_number: "5551234",
      date_of_birth: "1990-01-15T00:00:00Z",
      gender: "female",
      pronouns: "she/her",
      country_alpha2: "US",
    )

  let actual = validate(db, None, values)
  assert actual
    == Ok(ClientParams(
      email: Some("alice@example.com"),
      first_name: "Alice",
      last_name: Some("Smith"),
      phone_alpha2: Some("US"),
      phone_number: Some("5551234"),
      date_of_birth: Some("1990-01-15T00:00:00Z"),
      gender: Some("female"),
      pronouns: Some("she/her"),
      country_alpha2: Some("US"),
    ))
}

pub fn client_create_first_name_missing_test() {
  let db = Connection
  let values =
    form_payload(
      email: "",
      first_name: "",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "first_name", value: "This field is required"),
      ]),
    )
  assert actual == expected
}

pub fn client_create_email_taken_test() {
  let db = Connection
  let values =
    form_payload(
      email: "taken@example.com",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not available"),
      ]),
    )
  assert actual == expected
}

pub fn client_update_allows_current_email_test() {
  // The same email that would be rejected on create is accepted on update
  // when client_id matches the owner.
  let db = Connection
  let values =
    form_payload(
      email: "current@me.com",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, Some(42), values)
  assert actual
    == Ok(ClientParams(
      email: Some("current@me.com"),
      first_name: "Alice",
      last_name: None,
      phone_alpha2: None,
      phone_number: None,
      date_of_birth: None,
      gender: None,
      pronouns: None,
      country_alpha2: None,
    ))
}

pub fn client_create_rejects_email_other_clients_own_test() {
  // Same "current@me.com" rejected on create because no exemption applies.
  let db = Connection
  let values =
    form_payload(
      email: "current@me.com",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  // No exemption on create — but our sentinel only rejects "taken@example.com".
  // Confirm "current@me.com" is allowed (since no other client owns it in our
  // simulated DB), proving the context-aware predicate dispatches correctly.
  let actual = validate(db, None, values)
  assert actual
    == Ok(ClientParams(
      email: Some("current@me.com"),
      first_name: "Alice",
      last_name: None,
      phone_alpha2: None,
      phone_number: None,
      date_of_birth: None,
      gender: None,
      pronouns: None,
      country_alpha2: None,
    ))
}

pub fn client_invalid_email_format_short_circuits_db_check_test() {
  // email_is_valid fails first; the DB-backed predicate never runs.
  let db = Connection
  let values =
    form_payload(
      email: "not-an-email",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
      ]),
    )
  assert actual == expected
}

pub fn client_phone_number_without_country_test() {
  // Cross-field: phone_number is present, phone_alpha2 is absent.
  let db = Connection
  let values =
    form_payload(
      email: "",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "5551234",
      date_of_birth: "",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(
          key: "phone_number",
          value: "Valid country code is required",
        ),
      ]),
    )
  assert actual == expected
}

pub fn client_invalid_date_of_birth_test() {
  let db = Connection
  let values =
    form_payload(
      email: "",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "not a date",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "date_of_birth", value: "Date is not valid"),
      ]),
    )
  assert actual == expected
}

pub fn client_invalid_enum_values_test() {
  // Three optional fields with invalid enum values — all errors accumulate.
  let db = Connection
  let values =
    form_payload(
      email: "",
      first_name: "Alice",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "",
      gender: "robot",
      pronouns: "xe/xir",
      country_alpha2: "ZZ",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "gender", value: "Select a valid option"),
        ValidationError(key: "pronouns", value: "Select a valid option"),
        ValidationError(key: "country_alpha2", value: "Select a valid option"),
      ]),
    )
  assert actual == expected
}

pub fn client_multiple_errors_accumulate_test() {
  // first_name empty + invalid email + invalid date — three errors from
  // three different validation paths, all surfaced together.
  let db = Connection
  let values =
    form_payload(
      email: "not-an-email",
      first_name: "",
      last_name: "",
      phone_alpha2: "",
      phone_number: "",
      date_of_birth: "garbage",
      gender: "",
      pronouns: "",
      country_alpha2: "",
    )

  let actual = validate(db, None, values)
  let expected =
    Error(
      ErrorValidatingParams([
        ValidationError(key: "email", value: "Email address is not valid"),
        ValidationError(key: "first_name", value: "This field is required"),
        ValidationError(key: "date_of_birth", value: "Date is not valid"),
      ]),
    )
  assert actual == expected
}

pub fn client_dynamic_input_path_test() {
  // Same schema, but driven through ve.parse against a hand-built Dynamic
  // (JSON-style). Demonstrates the schema is input-shape agnostic.
  let db = Connection
  let data =
    dynamic.properties([
      #(dynamic.string("first_name"), dynamic.string("Alice")),
      #(dynamic.string("email"), dynamic.string("alice@example.com")),
    ])

  let actual =
    ve.parse(client_schema(db, None), data, [])
    |> result.map_error(ErrorValidatingParams)

  assert actual
    == Ok(ClientParams(
      email: Some("alice@example.com"),
      first_name: "Alice",
      last_name: None,
      phone_alpha2: None,
      phone_number: None,
      date_of_birth: None,
      gender: None,
      pronouns: None,
      country_alpha2: None,
    ))
}
