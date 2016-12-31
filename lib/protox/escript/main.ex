defmodule Protox.Escript.Main do

  @moduledoc false

  def main(_args) do
    case System.get_env("PROTOX_ESCRIPT_MODE") do
      "CONFORMANCE" -> Protox.Escript.Conformance.run()
      "BENCHMARK"   -> Protox.Escript.Benchmark.run()
    end

  end

end
