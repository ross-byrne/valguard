//// Experimental features

/// A general type of validation that is returned as a list
pub type Validation {
  Validation(key: String, success: Bool, message: String, error_code: Error)
}

/// a single validation item that contains a list of issues
///
/// This model could then be one part of a result or enum
pub type ValidationV2 {
  ValidationV2(success: Bool, issues: List(Issue))
}

pub type Issue {
  Issue(key: String, message: String, error: Error)
}

/// Another option, where returned validation is either success,
/// which will include the validated params
///
/// Or, it will be a validation error and include a list of issues
pub type ValidationType(a) {
  Success(a)
  Error(List(Issue))
}

/// A list of all types of validation errors that can occur
pub type Error {
  StringRequired
  StringTooShort
  StringTooLong
  StringNotEqual
  IntRequired
  IntTooSmall
  IntTooLarge
  IntNotEqual
  FloatRequired
  FloatTooSmall
  FloatTooLarge
  FloatNotEqual
  BoolNotEqual
  TimestampNotValid
  TimestampNotEqual
  DateNotValid
  DateNotEqual
  EmailNotValid
}

pub fn testing() {
  echo "Testing types and shapes"
}
