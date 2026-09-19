# Protox Benchmark

All the following commands are executed from the root of the project.

## Launch the benchmark

- you can specify the task to run (`encode` or `decode`)
- you can control run durations with flags (defaults shown below)
- you have to specify the benchmark tag, which will be used to identify the benchmark run
- benchmark results are stored in `./benchmark/output/benchee/<TASK>-<HHMMSS>-<BENCHMARK_TAG>.benchee`

```shell
mix protox.benchmark.run [--task <TASK>] [--warmup 2] [--time 5] [--memory-time 2] [--reduction-time 2] <BENCHMARK_TAG>
```

Examples:

```shell
# Short run (defaults)
mix protox.benchmark.run --task decode my_tag

# Longer run to reduce variance
mix protox.benchmark.run --task encode --warmup 3 --time 15 --memory-time 5 --reduction-time 5 my_long_tag
```

As a sanity check, before measuring anything, the run re-encodes every message in the corpus and checks it against the size recorded when the corpus was generated.

You can restrict any run to a subset of the corpus:

```shell
mix protox.benchmark.run --task decode --input maps,test_all_types_proto3 my_tag
```

## Profile the code

`--profile-after` switches the task into a profiling mode: Benchee runs each scenario exactly once under a profiler, after everything else.

```shell
mix protox.benchmark.run --task encode --profile-after tprof --profile-type memory --input synthetic_200
```

| Flag              | Values                                 | Default  |
| ----------------- | -------------------------------------- | -------- |
| `--profile-after` | `tprof`, `cprof`, `eprof`, `fprof`     | —        |
| `--profile-type`  | `memory`, `calls`, `time` (tprof only) | `memory` |
| `--profile-scope` | `module`, `codec`, `all` (tprof only)  | `module` |

## Aggregate the results

```shell
mix protox.benchmark.report <BENCHMARK_RESULT_PATHS>
```

Example:

```shell
mix protox.benchmark.report ./benchmark/output/benchee/encode-*
```

This prints a console comparison and writes an HTML report to `./benchmark/output/html/`.

## The corpus

Every run reads `./benchmark/benchmark_payloads.bin`, a compressed `:erlang.term_to_binary` map of `input_name => {module, [{message, size, bytes}]}`.

Regenerate it with:

```shell
mix protox.benchmark.generate.payloads
```

> [!WARNING]
> Generation is not seeded, so regenerating produces an entirely different corpus and makes every previously saved `.benchee` file incomparable.

Add new `.proto` files in `compile_benchmark_protos.ex`.

### Value distributions

Payloads are generated with `Protox.RandomInit`, using a _profile_:

- `Protox.Benchmark.RealisticValues`: production-like values for benchmarking.
- `Protox.RandomInit.EdgeCase`: the profile the test suite uses, which deliberately over-produces NaN, Infinity, full-range integers and non-ASCII strings.

### The inputs

| Input                                | Source    | Notes                                                  |
| ------------------------------------ | --------- | ------------------------------------------------------ |
| `google_message1_proto3` / `_proto2` | captured  | Real Google production payloads, 228 bytes each        |
| `synthetic_5` … `synthetic_200`      | generated | Synthetic messages with 5 to 200 fields                |
| `maps`                               | generated | Map-heavy; the synthetic distribution contains no maps |
| `otel_traces_data`                   | generated | OpenTelemetry `TracesData`, real schema                |
| `prometheus_write_request`           | generated | Prometheus remote-write, real schema                   |
| `test_all_types_proto3`              | generated | The conformance suite's mega-message                   |
| `synthetic_100_edge`                 | generated | `EdgeCase` twin of `synthetic_100`                     |
| `edge_*`                             | generated | One saturated encoder path each                        |

### Provenance of the synthetic protos

`protos/synthetic_*.proto` are frozen artifacts. They were generated once using field types and labels from the weighted distribution used by Google's own protobuf benchmarks:

<https://github.com/protocolbuffers/protobuf/blob/336d6f04e94efebcefb5574d0c8d487bcb0d187e/benchmarks/gen_synthetic_protos.py>
