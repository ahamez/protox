defmodule Protox.CompileBenchmarkProtos do
  @moduledoc false
  use Protox, files: Path.wildcard("./benchmark/protos/*.proto")
end
