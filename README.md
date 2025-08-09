# valguard

[![Package Version](https://img.shields.io/hexpm/v/valguard)](https://hex.pm/packages/valguard)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/valguard/)

A Gleam validation library for validating backend api params. Currently a work-in-progress.
Better documentation and examples Coming Soon™.

## Motivation

After building a sizable backend api in gleam, I found I was writing a lot of boilerplate code
to validate my endpoint params for each of my APIs. There are existing libraries for this but
I personally didn't like how they worked, so I started to build my own internally.
The main goal was to enforce param validation and customise the per-field validation error
that gets returned to the client.

Now, I feel like my solution has matured enough to be useful to others so I'm moving it out into
this package.

## Development

```sh
mise up     # Install dependencies

gleam run   # Run the project
gleam test  # Run the tests
```
