defmodule Mix.Tasks.Protox.Conformance do

  use Mix.Task

  def run(args) do
    {options, _} = OptionParser.parse!(args)
    runner = Keyword.fetch!(options, :runner)
    Mix.Tasks.Escript.Build.run([])
    Mix.shell.cmd("#{runner} --enforce_recommended ./protox_conformance")
  end

end
