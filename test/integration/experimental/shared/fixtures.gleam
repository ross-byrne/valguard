//// Test util for the experimental integration tests: load a JSON fixture
//// from disk and parse it into a `Dynamic` without running any validation.
////
//// `decode.dynamic` is a passthrough decoder, so `json.parse` here only fails
//// when the JSON itself is malformed — not when the shape doesn't match a
//// schema.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import simplifile

const fixtures_dir = "test/integration/experimental/fixtures"

pub fn load(name: String) -> dynamic.Dynamic {
  let assert Ok(body) = simplifile.read(fixtures_dir <> "/" <> name)
  let assert Ok(value) = json.parse(body, decode.dynamic)
  value
}
