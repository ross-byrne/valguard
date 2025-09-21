import gleam/option
import valguard/internal/utils

pub fn some_or_returns_value_if_some_test() {
  let value = option.Some("test")
  let result = {
    use val <- utils.some_or(value, Error("oops"))
    assert val == "test"
    Ok(val)
  }
  assert result == Ok("test")
}

pub fn some_or_returns_return_value_if_none_test() {
  let value = option.None
  let result = {
    use _val <- utils.some_or(value, Error("oops"))
    panic as "unreachable state"
  }
  assert result == Error("oops")
}
