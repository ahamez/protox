defmodule Mix.Tasks.Protox.Benchmark do

  @moduledoc false

  use Mix.Task

  def run(_args) do
    Mix.Tasks.Escript.Build.run([])
    Mix.shell.cmd("PROTOX_ESCRIPT_MODE=BENCHMARK ./protox")
  end

end
