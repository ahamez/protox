defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  @options [
    tag: :string
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, _argv, []} <- OptionParser.parse(args, strict: @options),
         tag <- get_tag(opts),
         payloads <- get_payloads("./benchmark/benchmark_payloads.bin") do
      run_benchee(tag, payloads, :encode)
      run_benchee(tag, payloads, :decode)
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp run_benchee(tag, payloads, task) do
    jobs =
      case task do
        :encode ->
          %{
            "encode" => fn input ->
              Enum.map(input, fn {msg, _size, _bytes} -> msg.__struct__.encode!(msg) end)
            end
          }

        :decode ->
          %{
            "decode" => fn input ->
              Enum.map(input, fn {msg, _size, bytes} -> msg.__struct__.decode!(bytes) end)
            end
          }
      end

    Benchee.run(
      jobs,
      inputs: payloads,
      save: [
        path: Path.join(["./benchmark", "#{task}-#{tag}.benchee"]),
        tag: "#{task}-#{tag}"
      ],
      load: ["./benchmark/#{task}*.benchee"],
      time: 5,
      memory_time: 2,
      reduction_time: 2,
      formatters: [
        {Benchee.Formatters.HTML, file: "benchmark/output/#{task}-#{tag}.html"},
        Benchee.Formatters.Console
      ]
    )
  end

  defp get_tag(opts) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d-%H%S")

    case Keyword.get(opts, :tag, nil) do
      nil -> timestamp
      tag -> "#{timestamp}-#{tag}"
    end
  end

  def get_payloads(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
