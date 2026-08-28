# Protox Benchmark

All the following commands are executed from the root of the project.

## Launch the benchmark

- you can specify the task to run (`encode` or `decode`)
- you can control run durations with flags (defaults shown below)
- you have to specify the benchmark tag, which will be used to identify the benchmark run
- benchmark results are stored in `./benchmark/output/benchee/<TASK>-<HHMMSS>-<BENCHMARK_TAG>.benchee`

```
mix protox.benchmark.run [--task <TASK>] [--warmup 2] [--time 5] [--memory-time 2] [--reduction-time 2] <BENCHMARK_TAG>
```

Example:

```
# Short run (defaults)
mix protox.benchmark.run --task decode my_tag

# Longer run to reduce variance
mix protox.benchmark.run --task encode --warmup 3 --time 15 --memory-time 5 --reduction-time 5 my_long_tag
```

Before measuring anything, the run re-encodes every message in the corpus and checks it
against the size recorded when the corpus was generated. This is cheap and happens
outside the measured region; it exists because an optimization that silently drops
fields would otherwise post excellent numbers. It only catches size-changing breakage
on the encoding side — `mix test` and `mix protox.conformance` remain the real
correctness checks.

## Aggregate the results

```
mix protox.benchmark.report <BENCHMARK_RESULT_PATHS>
```

Example:

```
mix protox.benchmark.report ./benchmark/output/benchee/encode-*
```

This prints a console comparison and writes an HTML report to
`./benchmark/output/html/`. Benchee matches scenarios across runs by input name, so
renaming an input makes previously saved suites incomparable with new ones.

## The corpus

Every run reads `./benchmark/benchmark_payloads.bin`, a compressed `:erlang.term_to_binary`
map of `module => [{message, size, bytes}]`. It is committed (via Git LFS) so that runs
are comparable across machines and over time.

`size` is the number of bytes protox produces when encoding `message`, and `bytes` is
what gets fed to the decoder. These are the same value everywhere except for the
captured Google datasets — see `protos/vendor/README.md`.

Regenerate it with:

```
mix protox.benchmark.generate.payloads
```

> [!WARNING]
> Generation is not seeded, so regenerating produces an entirely different corpus and
> makes every previously saved `.benchee` file incomparable. Only do this deliberately.

The inputs, smallest to largest:

| Input | Source | Notes |
| --- | --- | --- |
| `google_message1_proto3` / `_proto2` | captured | Real Google production payloads, 228 bytes each |
| `synthetic_5` … `synthetic_200` | generated | Synthetic messages with 5 to 200 fields |
| `maps` | generated | Map-heavy; the synthetic distribution contains no maps |
| `otel_traces_data` | generated | OpenTelemetry `TracesData`, real schema |
| `test_all_types_proto3` | generated | The conformance suite's mega-message |
| `ascii` | generated | String-heavy with pure-ASCII contents |
| `prometheus_write_request` | generated | Prometheus remote-write, real schema |

Third-party schemas live in `protos/vendor/`; that directory's `README.md` records where
each came from, its licence, and what was modified.

### Provenance of the synthetic protos

`protos/synthetic_*.proto` are frozen artifacts. They were generated once by a mix task
(removed in favour of this note, since it had bit-rotted and could no longer reproduce
them) that drew field types and labels from the weighted distribution used by Google's
own protobuf benchmarks:

<https://github.com/protocolbuffers/protobuf/blob/336d6f04e94efebcefb5574d0c8d487bcb0d187e/benchmarks/gen_synthetic_protos.py>

In that distribution a typical field is a `string` (25.5% singular, 2.6% repeated),
a sub-`Message` (22.5% / 7.8%), an `int64` (9.7% / 0.4%), a `bool` (8.3%), an `int32`
(6.7%) or an `Enum` (6.2%). It contains no map fields at all, which is why the `maps`
input exists separately.
