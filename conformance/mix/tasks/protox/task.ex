defmodule Mix.Tasks.Protox.Conformance do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, _, []} <- OptionParser.parse(args, strict: [runner: :string, quiet: :boolean]),
         {:ok, runner} <- Keyword.fetch(options, :runner),
         quiet <- Keyword.get(options, :quiet, false),
         :ok <- Mix.Tasks.Escript.Build.run([]),
         :ok <- launch(runner, quiet) do
      {:ok, :conformance_successful}
    else
      {:error, :runner_failure} -> {:ok, :conformance_failure}
      e -> e
    end
  end

  defp launch(runner, quiet) do
    shell =
      case quiet do
        true -> Mix.Shell.Quiet
        false -> Mix.Shell.IO
      end

    case shell.cmd(
           "#{runner} --enforce_recommended --failure_list ./conformance/failure_list.txt ./protox_conformance"
         ) do
      0 -> :ok
      1 -> {:error, :runner_failure}
      126 -> {:error, :cannot_execute_runner}
      127 -> {:error, :no_such_file_or_directory}
      code -> {:error, code}
    end
  end
end
