import gleam/option.{None, Some}
import youid/uuid

/// returns Some(a) in a callback or returns b
pub fn some_or(
  option: option.Option(a),
  return return: b,
  apply fun: fn(a) -> b,
) -> b {
  case option {
    None -> return
    Some(value) -> fun(value)
  }
}

/// Checks if a string is a specific uuid version
pub fn check_uuid_version(value: String, ver: uuid.Version) -> Bool {
  case uuid.from_string(value) {
    Error(_) -> False
    Ok(uuid) -> uuid.version(uuid) == ver
  }
}
