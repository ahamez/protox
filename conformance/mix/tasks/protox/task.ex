defmodule Mix.Tasks.Protox.Conformance do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, _, []} <- OptionParser.parse(args, strict: [runner: :string]),
         {:ok, runner} <- Keyword.fetch(options, :runner),
         :ok <- Mix.Tasks.Escript.Build.run([]),
         :ok <- launch(runner) do
      {:ok, :conformance_successful}
    else
      #
      {:error, :runner_failure} -> {:ok, :conformance_failure}
      e -> e
    end
  end

  defp launch(runner) do
    case Mix.Shell.Quiet.cmd("#{runner} --enforce_recommended ./protox_conformance") do
      0 -> :ok
      1 -> {:error, :runner_failure}
      126 -> {:error, :cannot_execute_runner}
      127 -> {:error, :no_such_file_or_directory}
      code -> {:error, code}
    end
  end
end
