defmodule Mix.Tasks.Protox.Benchmark.Report do
  @moduledoc false

  use Mix.Task

  alias Benchee.Formatters.{Console, HTML}

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {_opts, argv, []} <- OptionParser.parse(args, strict: []),
         {:ok, files} <- get_files(argv) do
      Benchee.report(
        load: files,
        formatters: [
          {Console, extended_statistics: true},
          {HTML, file: "benchmark/output/html/report.html"}
        ]
      )
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp get_files([]), do: {:error, "No files provided"}
  defp get_files(argv), do: {:ok, argv}
end
