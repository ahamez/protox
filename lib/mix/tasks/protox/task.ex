defmodule Mix.Tasks.Protox.Conformance do
  @moduledoc false

  use Mix.Task

  def run(args) do
    {options, _} = OptionParser.parse!(args, strict: [runner: :string])
    runner = Keyword.fetch!(options, :runner)
    Mix.Tasks.Escript.Build.run([])
    Mix.shell().cmd("#{runner} --enforce_recommended ./protox_conformance")
  end
end
