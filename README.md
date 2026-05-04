# valguard

[![Package Version](https://img.shields.io/hexpm/v/valguard)](https://hex.pm/packages/valguard)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/valguard/)

A Gleam validation library for form and api endpoint validation. Currently a work-in-progress.
Better documentation and examples Coming Soon™.

## Examples

An example of validating a login form:

```gleam
import valguard.{type ValidationError}
import valguard/validate as v

/// Your custom validation error type that wraps valguard error type
pub type Errors {
  ErrorValidatingParams(List(ValidationError))
}

/// Your login endpoint params
type LoginParams {
  LoginParams(email: String, password: String)
}

// your code here...

/// Validates login params, where `ErrorValidatingParams` is your own validation error type.
///
/// Function returns a result with a list of validation errors. These errors
/// can be used to build a map of key value pairs, where the keys is the param name and value
/// is the validation error message.
fn validate_params(params: LoginParams) -> Result(Nil, Errors) {
  [
    valguard.with("email", params.email, [
      v.string_required(_, "This field is required"),
      v.email_is_valid(_, "Email address is not valid"),
    ]
    ),
    valguard.with("password", params.password, [
      v.string_required(_, "This field is required"),
    ]),
  ]
  |> valguard.collect_errors
  |> valguard.prepare_with(ErrorValidatingParams)
}
```

## Experimental: parse + validate pipeline

The `valguard/experimental` module is a parallel API that takes raw `Dynamic`
input (e.g. a form payload or JSON body) and returns either a typed record or
a list of every accumulated parse and validation error. A schema is just a
`gleam/dynamic/decode.Decoder(t)` that you declare once and pass to
`ve.parse(schema, data)`.

```gleam
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import valguard.{type ValidationError}
import valguard/experimental as ve
import valguard/validate as v

type LoginParams {
  LoginParams(email: String, password: String)
}

type Errors {
  ErrorValidatingParams(List(ValidationError))
}

/// Schema declared as a function returning a Schema. Pass it to ve.parse.
fn login_schema() -> ve.Schema(LoginParams) {
  use email <- ve.field_with("email", decode.string, [
    v.string_required(_, "This field is required"),
    v.email_is_valid(_, "Email address is not valid"),
  ])
  use password <- ve.field_with("password", decode.string, [
    v.string_required(_, "This field is required"),
  ])
  decode.success(LoginParams(email, password))
}

fn validate_login(data: dynamic.Dynamic) -> Result(LoginParams, Errors) {
  ve.parse(login_schema(), data)
  |> result.map_error(ErrorValidatingParams)
}
```

For cross-field checks (e.g. password / confirm_password match), the
recommended pattern is two-phase: run `ve.parse` first, then use
`valguard.list` against the parsed record. See
`test/integration/experimental/user_registration_test.gleam` for a full
example. A one-pass `ve.success_with` is also available if you'd rather keep
cross-field checks inside the schema.

This module is experimental and may change before being promoted into the
main `valguard` module.

## Goals

- Perform exhaustive param validation for good form validation UX. Don't just stop on the first error
- Reduce repetitive boilerplate when trying to validate endpoint params
- Look and feel nice to use

## Motivation

After building a sizeable backend api in gleam, I found I was writing a lot of boilerplate code
to validate my endpoint params for each of my APIs. There are existing libraries for this but
I personally wasn't a fan of their API, so I started to build my own internally.
The main goal was to enforce param validation and customise the per-field validation errors
that get returned to the client. This allows for a nice form validation UX but can also be used
generally to enforce arbitrary requirements on params submitted to your endpoints.

## Development

```sh
mise up     # Install dependencies

gleam run   # Run the project
gleam test  # Run the tests
```
