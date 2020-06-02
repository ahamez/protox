defmodule Mix.Tasks.Protox.Conformance do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, _, []} <- OptionParser.parse(args, strict: [runner: :string]),
         {:ok, runner} <- Keyword.fetch(options, :runner),
         :ok <- Mix.Tasks.Escript.Build.run([]) do
      Mix.shell().cmd("#{runner} --enforce_recommended ./protox_conformance")
    end
  end
end
