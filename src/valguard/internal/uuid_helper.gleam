//// Code taken from package `youid`. See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L1

import gleam/string

/// Possible UUID versions.
pub type Version {
  V1
  V2
  V3
  V4
  V5
  V7
  VUnknown
}

/// Checks if a string is a specific uuid version
pub fn check_uuid_version(uuid: String, ver: Version) -> Bool {
  case string_is_uuid(uuid) {
    Error(_) -> False
    Ok(bits) ->
      case version(bits) {
        v if v == ver -> True
        _ -> False
      }
  }
}

/// Attempt to decode a UUID from a string. Supports strings formatted in the same
/// ways this library will output them. Hex with dashes, hex without dashes and
/// hex with or without dashes prepended with "urn:uuid:"
///
/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L463
fn string_is_uuid(in: String) -> Result(BitArray, Nil) {
  let hex = case in {
    "urn:uuid:" <> in -> in
    _ -> in
  }

  case to_bit_array_helper(hex) {
    Ok(bits) -> Ok(bits)
    Error(_) -> Error(Nil)
  }
}

/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L529
fn to_bit_array_helper(str: String) -> Result(BitArray, Nil) {
  to_bitstring_help(str, 0, <<>>)
}

/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L533
fn to_bitstring_help(
  str: String,
  index: Int,
  acc: BitArray,
) -> Result(BitArray, Nil) {
  case string.pop_grapheme(str) {
    Error(Nil) if index == 32 -> Ok(acc)
    Ok(#("-", rest)) if index < 32 -> to_bitstring_help(rest, index, acc)
    Ok(#(c, rest)) if index < 32 ->
      case hex_to_int(c) {
        Ok(i) -> to_bitstring_help(rest, index + 1, <<acc:bits, i:size(4)>>)
        Error(_) -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

/// Hex Helper
/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L573
fn hex_to_int(c: String) -> Result(Int, Nil) {
  let i = case c {
    "0" -> 0
    "1" -> 1
    "2" -> 2
    "3" -> 3
    "4" -> 4
    "5" -> 5
    "6" -> 6
    "7" -> 7
    "8" -> 8
    "9" -> 9
    "a" | "A" -> 10
    "b" | "B" -> 11
    "c" | "C" -> 12
    "d" | "D" -> 13
    "e" | "E" -> 14
    "f" | "F" -> 15
    _ -> 16
  }
  case i {
    16 -> Error(Nil)
    x -> Ok(x)
  }
}

/// Determine the Version of a UUID
/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L336
fn version(bits: BitArray) -> Version {
  let assert <<_:48, ver:4, _:76>> = bits
  decode_version(ver)
}

/// See: https://github.com/lpil/youid/blob/b623162b8eea145c47c15bac55afe7e482f01b48/src/youid/uuid.gleam#L550
fn decode_version(int: Int) -> Version {
  case int {
    1 -> V1
    2 -> V2
    3 -> V3
    4 -> V4
    5 -> V5
    7 -> V7
    _ -> VUnknown
  }
}
