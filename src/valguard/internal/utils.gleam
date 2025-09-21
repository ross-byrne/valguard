import gleam/option.{None, Some}

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
