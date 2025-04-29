# How to contribute to protox

First, thank you for your interest in contributing to protox!

To ensure a smooth experience while contributing, here are a few handy guidelines.

## Development Prerequisites

- Erlang/OTP 26 or later
- Elixir 1.15 or later
- (optional) [lefthook](https://evilmartians.github.io/lefthook/installation) for git hooks

## Development Guidelines

We use a few tools to keep the code clean and consistent:

- [`mix deps.unlock --check-unused`](https://hexdocs.pm/mix/Mix.Tasks.Deps.Unlock.html) to check for unused dependencies
- [`mix format --check-formatted`](https://hexdocs.pm/mix/Mix.Tasks.Format.html) to check for code formatting issues
- [`mix credo`](https://hexdocs.pm/credo/Mix.Tasks.Credo.html) for code style and consistency checks
- [`mix dialyzer`](https://hexdocs.pm/dialyxir/Mix.Tasks.Dialyzer.html) for type checking
- [`mix muzak`](https://hexdocs.pm/muzak_pro/muzak-pro.html) for mutation testing
- `mix test --include conformance` for testing

> [!NOTE]
>
> These tasks are always run in the CI pipeline.

> [!NOTE]
>
> `lefthook` can be used to run these tasks automatically on each commit or push (except for the `muzak` task which takes a long time to run).

> [!NOTE]
>
> `mix test --include conformance` automatically downloads and compiles the conformance test suite and runs it against the current version of protox.

### Testing

Correctness is the main goal of Protox, here's how you can contribute to it:

- add tests for any new features;
- when fixing a bug, add tests that reproduce the bug;
- ensure all tests pass with `mix test --include conformance`;
- try to maintain or improve test coverage (check with `mix test --cover`).

### Documentation

Documentation is as important as correctness, here's a quick reminder of the things to keep in mind:

- document public functions;
- update module documentation if needed;
- if possible, include examples as [doctests](https://hexdocs.pm/ex_unit/ExUnit.DocTest.html);
- update the main [README.md](./README.md) if needed.

## License

By contributing to Protox, you agree that your contributions will be licensed under MIT License.

## Getting Help

If you have questions or need help, you can:

- Send me a direct message on [Elixir Forum](https://elixirforum.com/u/ahamez).
- Send me an email at alexandre.hamez at gmail.com.
- Open an issue.
- Start a [discussion](https://github.com/ahamez/protox/discussions).
