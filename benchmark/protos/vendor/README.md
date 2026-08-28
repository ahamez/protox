# Vendored benchmark schemas

Third-party `.proto` files, and where they came from. Everything here is vendored
rather than fetched at build time so that a benchmark run is reproducible offline and
pinned to an exact upstream revision.

## `google/` — Google's protobuf benchmark datasets

- Source: <https://github.com/protocolbuffers/protobuf/tree/v21.12/benchmarks/datasets>
- Licence: BSD-3-Clause (see `google/LICENSE`)
- Files: `benchmark_message1_proto2.proto`, `benchmark_message1_proto3.proto`,
  `benchmarks.proto`, and the matching `dataset.google_message1_proto*.pb`

`benchmarks.proto` defines the `BenchmarkDataset` wrapper that each `.pb` file uses:
a name, a fully-qualified message name, and `repeated bytes payload`. These payloads
are **real captured Google production messages**, not generated data, and they are the
corpus other protobuf implementations publish numbers against.

Two things to know:

- These datasets were **deleted from protobuf after v21.12** (they are absent at v25.3
  and at the 34.1 the conformance suite pins), so v21.12 is the last revision that has
  them and they will not be updated upstream again.
- `google_message2` is deliberately **not** vendored. It declares `repeated group
  Group1 = 10`, and groups are an unsupported feature of protox (see the README's
  "Unsupported features"). Decoding its payload raises `invalid wire type 3`, and
  protox cannot skip a group as an unknown field either, so there is no way to use it.

`dataset.google_message1_proto3.pb` does not round-trip byte-identically: the captured
bytes contain explicitly-written default values, which proto3 semantics omit on
re-encode (228 bytes in, 221 bytes out). This is correct behaviour, not a defect. See
the note on `size` in `mix/tasks/protox/benchmark/generate/payloads.ex`.

## `otel/` — OpenTelemetry trace protocol

- Source: <https://github.com/open-telemetry/opentelemetry-proto/tree/v1.7.0>
- Licence: Apache-2.0 (see `otel/LICENSE`)
- Files: `opentelemetry/proto/{trace/v1/trace,common/v1/common,resource/v1/resource}.proto`

Unmodified. Benchmarked through the `TracesData` root message. Payloads are generated,
not captured, so this contributes a realistic message *shape* — deep nesting and
`KeyValue` attribute lists — rather than realistic data.

## `prometheus/` — Prometheus remote-write

- Source: <https://github.com/prometheus/prometheus/tree/v3.6.0/prompb>
- Licence: Apache-2.0 (see `prometheus/LICENSE`)
- Files: `remote.proto`, `types.proto`

**Modified.** Every Prometheus `prompb` variant imports `gogoproto/gogo.proto`, which
protoc cannot resolve without also vendoring the archived gogo/protobuf project. The
import and all `[(gogoproto.*) = ...]` options were stripped. Those annotations are Go
codegen hints and carry no wire-format meaning, so the encoding measured here is
identical to upstream. Each file carries a header comment recording this.

Benchmarked through the `WriteRequest` root message; payloads are generated. This
contributes the large-repeated-numeric shape that neither Google nor OTel covers.
