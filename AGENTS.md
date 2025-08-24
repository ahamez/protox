# Repository Guidelines

## Project Structure & Module Organization

- `lib/protox/**`: Core library (encoding/decoding, generation, parsing). Mix tasks in `lib/mix/tasks/protox/*`.
- `test/**`: ExUnit tests and property tests (`*_test.exs`).
- `conformance/**`: Conformance runner and mix task; reports in `conformance_report/`.
- `benchmark/**`: Benchmarks and docs.
- `documentation/**`, `doc/`: User-facing docs; `doc/` is generated.
- `config/`, `mix.exs`, `mix.lock`: Build and project configuration.
- `priv/plts/`: Dialyzer PLT cache.

## Build, Test, and Development Commands

- Install deps: `mix deps.get`
- Compile (treat warnings as errors): `mix compile --warnings-as-errors`
- Unit tests: `mix test` (to include conformance test suite: `mix test --include conformance`)
- Coverage: `mix test --cover`
- Lint: `mix credo`
- Static analysis: `mix dialyzer`
- Format: `mix format`
- Docs: `mix docs`
- Codegen from .proto: `mix protox.generate --output-path=lib/messages.ex --include-path=. defs/foo.proto`
- Conformance suite: `mix protox.conformance` (requires `PROTOX_PROTOBUF_VERSION`, CI uses `29.2`)
- Address warnings before opening a PR.

## Coding Style & Naming Conventions

- Elixir ≥ 1.15, OTP ≥ 26.
- Max line length: 120.
- Naming: Modules `PascalCase`, functions/variables `snake_case`.
- Tests live under `test/**`, files end with `_test.exs`.
- Formatting: `mix format` (configured via `.formatter.exs`, uses Quokka plugin).
- Linting: Credo defaults in `.credo.exs`;

## Testing Guidelines

- Frameworks: ExUnit + StreamData. Prefer fast, deterministic tests.
- Property tests: keep generators in `test/support/**` when reusable.
- Conformance tests are tagged `@tag :conformance`; run explicitly when needed.
- Aim to keep coverage high (≥ 95%); add tests for new logic and edge cases.

## Commit & Pull Request Guidelines

- Commit style: follow Conventional Commit (e.g., `feat:`, `fix:`, `doc:`, `ci:`, `chore:`).
- PRs: include a clear description, linked issues, and before/after notes when applicable.
- Required checks locally: `mix format --check-formatted`, `mix credo`, `mix dialyzer`, `mix test` (optionally include conformance).
- Hooks: repo includes Lefthook config. Optionally run `lefthook install` to enable pre-commit/push checks.

## Configuration Tips

- `protoc` must be in `PATH` for development/build.
- Optional env vars: `PROTOX_MUZAK_PRO_CREDS` (mutation testing), `PROTOX_PROTOBUF_VERSION` (to build conformance runner).

## Security

- Do not commit credentials.
