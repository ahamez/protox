defmodule Protox.CompileBenchmarkProtos do
  @moduledoc false

  # Listed explicitly rather than globbed: protox records each file as an @external_resource
  # so edits trigger a recompile, but a *new* file matching a wildcard does not — it would
  # silently never be compiled. Adding a schema here is the step that makes it exist.
  #
  # The vendored schemas each need their own include path because their imports are written
  # relative to their own project root. See benchmark/protos/vendor/README.md for where they
  # come from and what was modified.
  use Protox,
    files: [
      "./benchmark/protos/synthetic_5.proto",
      "./benchmark/protos/synthetic_10.proto",
      "./benchmark/protos/synthetic_20.proto",
      "./benchmark/protos/synthetic_50.proto",
      "./benchmark/protos/synthetic_100.proto",
      "./benchmark/protos/synthetic_200.proto",
      "./benchmark/protos/maps.proto",
      "./benchmark/protos/ascii.proto",
      "./benchmark/protos/edge.proto",
      "./benchmark/protos/vendor/google/benchmarks.proto",
      "./benchmark/protos/vendor/google/benchmark_message1_proto2.proto",
      "./benchmark/protos/vendor/google/benchmark_message1_proto3.proto",
      "./benchmark/protos/vendor/otel/opentelemetry/proto/trace/v1/trace.proto",
      "./benchmark/protos/vendor/prometheus/remote.proto"
    ],
    paths: [
      "./benchmark/protos",
      "./benchmark/protos/vendor/google",
      "./benchmark/protos/vendor/otel",
      "./benchmark/protos/vendor/prometheus"
    ]
end
