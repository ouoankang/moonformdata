# Contributing

MoonFormData welcomes fixes, tests, examples, and documentation improvements.

## Development Setup

Install MoonBit, then run:

```bash
moon check
moon build
moon test
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
moon package --list
moon publish --dry-run
```

## Scope

Good contributions keep the library focused on reusable multipart behavior:

- Parser correctness and edge cases.
- Encoder interoperability.
- Validation and schema helpers.
- Security-oriented filename handling.
- Examples that are small and reproducible.
- Documentation that helps users integrate the package.

Large features such as streaming parsing, nested multipart support, and framework adapters should include design notes and tests because they change the public behavior surface.

## License

By contributing, you agree that your contribution is licensed under Apache-2.0.
