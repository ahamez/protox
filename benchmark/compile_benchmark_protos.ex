defmodule Protox.CompileBenchmarkProtos do
  @moduledoc false

  use Protox,
    files: [
      "./benchmark/protos/synthetic_5.proto",
      "./benchmark/protos/synthetic_10.proto",
      "./benchmark/protos/synthetic_20.proto",
      "./benchmark/protos/synthetic_50.proto",
      "./benchmark/protos/synthetic_100.proto",
      "./benchmark/protos/synthetic_200.proto",
      "./benchmark/protos/edge.proto",
      "./benchmark/protos/maps.proto",
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

  @external_resource "./benchmark/protos/vendor/otel/opentelemetry/proto/common/v1/common.proto"
  @external_resource "./benchmark/protos/vendor/otel/opentelemetry/proto/resource/v1/resource.proto"
  @external_resource "./benchmark/protos/vendor/prometheus/types.proto"
end
