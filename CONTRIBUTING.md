# How to contribute to protox
First, thank you for your interest in contributing to protox!

Here are some guidelines to follow and some tips when contributing to protox.

## Development Prerequisites
- Erlang/OTP 26 or later
- Elixir 1.15 or later
- (optional) [lefthook](https://evilmartians.github.io/lefthook/installation) for git hooks

## Development Guidelines
To enforce consistent code style and quality, we use the following tools:
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
> `mix test --include conformance` automatically downloads and compilesthe conformance test suite and runs it against the current version of protox.

### Testing
- Add tests for any new features or bug fixes.
- Ensure all tests pass with `mix test --include conformance`.
- Try to maintain or improve test coverage (check with `mix test --cover`).

### Documentation
- Document public functions using ExDoc format.
- Update module documentation when needed.
- If possible, include examples in documentation.
- Update README.md if needed.

## Pull Request Process
Submit a Pull Request with:
- Clear description of changes
- Reference to any related issues
- Examples of new functionality if applicable

## License
By contributing to Protox, you agree that your contributions will be licensed under MIT License.

## Getting Help
If you have questions or need help, you can:
- Send me a direct message on [Elixir Forum](https://elixirforum.com/u/ahamez).
- Send me an email at alexandre.hamez at gmail.com.
- Open an issue.
- Start a discussion at https://github.com/ahamez/protox/discussions.
