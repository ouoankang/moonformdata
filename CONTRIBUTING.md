# Contributing

MoonFormData welcomes fixes, tests, examples, and documentation improvements.

## Development Setup

Install MoonBit, then run:

```bash
moon fmt --check
moon check --deny-warn
moon build
moon test --deny-warn
moon run examples/basic
```

## Before Opening a Pull Request

Run the full verification set:

```bash
moon check
moon build
moon test
moon check --target js
moon build --target js
moon test --target js
moon run cmd/main
moon run examples/basic
moon info
moon package --list
moon publish --dry-run
```

## Scope

Good contributions keep the library focused on reusable multipart behavior:

- Parser correctness and edge cases.
- Encoder interoperability.
- Validation, schema, and upload contract helpers.
- Security-oriented filename handling.
- Examples that are small and reproducible.
- Documentation that helps users integrate the package.

Streaming byte parsing and large-file transport are outside MoonFormData's application-contract scope. Framework adapters should remain thin and keep endpoint schema, risk analysis, and diagnostics reusable.

## License

By contributing, you agree that your contribution is licensed under Apache-2.0.
