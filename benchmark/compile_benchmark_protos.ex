defmodule Protox.CompileBenchmarkProtos do
  @moduledoc false

  # The vendored schemas each need their own include path because their imports are
  # written relative to their own project root. See benchmark/protos/vendor/README.md
  # for where they come from and what was modified.
  use Protox,
    files:
      Path.wildcard("./benchmark/protos/*.proto") ++
        Path.wildcard("./benchmark/protos/vendor/google/*.proto") ++
        ["./benchmark/protos/vendor/otel/opentelemetry/proto/trace/v1/trace.proto"] ++
        ["./benchmark/protos/vendor/prometheus/remote.proto"],
    paths: [
      "./benchmark/protos",
      "./benchmark/protos/vendor/google",
      "./benchmark/protos/vendor/otel",
      "./benchmark/protos/vendor/prometheus"
    ]
end
