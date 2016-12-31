defmodule Mix.Tasks.Protox.Conformance do

  @moduledoc false

  use Mix.Task

  def run(args) do
    {options, _} = OptionParser.parse!(args)
    runner = Keyword.fetch!(options, :runner)
    Mix.Tasks.Escript.Build.run([])
    Mix.shell.cmd("PROTOX_ESCRIPT_MODE=CONFORMANCE #{runner} --enforce_recommended ./protox")
  end

end
