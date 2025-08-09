# valguard

[![Package Version](https://img.shields.io/hexpm/v/valguard)](https://hex.pm/packages/valguard)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/valguard/)

A Gleam validation library for validating backend api params. Currently a work-in-progress.
Better documentation and examples Coming Soon™.

## Examples

An example of validating a login form:

```gleam
import valguard.{type ValidationError}
import valguard/val

/// Your custom validation error type that wraps valguard error type
pub type Errors {
  ErrorValidatingParams(List(ValidationError))
}

/// Your login endpoint params
type LoginParams {
  LoginParams(email: String, password: String)
}

// your code here...

/// Validates login params, where `ErrorValidatingParams` is your own validation error type
fn validate_params(params: LoginParams) -> Result(Nil, Errors) {
  [
    valguard.with("email", params.email, [val.required, val.email_is_valid]),
    valguard.with("password", params.password, [val.required]),
  ]
  |> valguard.collect_errors
  |> valguard.prepare_with(ErrorValidatingParams)
}
```

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

Now, I feel like my solution has matured enough to be useful to others so I'm moving it out into
this package.

## Development

```sh
mise up     # Install dependencies

gleam run   # Run the project
gleam test  # Run the tests
```
