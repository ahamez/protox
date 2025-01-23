defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  @options [
    tag: :string,
    task: :string
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, _argv, []} <- OptionParser.parse(args, strict: @options),
         tasks <- get_tasks(opts),
         tag <- get_tag(opts),
         payloads <- get_payloads("./benchmark/benchmark_payloads.bin") do
      run_benchee_tasks(tag, payloads, tasks)
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp run_benchee_tasks(tag, payloads, tasks) do
    Enum.each(tasks, fn task ->
      job =
        case task do
          :encode ->
            %{
              encode: fn input ->
                Enum.map(input, fn {msg, _size, _bytes} -> msg.__struct__.encode!(msg) end)
              end
            }

          :decode ->
            %{
              decode: fn input ->
                Enum.map(input, fn {msg, _size, bytes} -> msg.__struct__.decode!(bytes) end)
              end
            }
        end

      run_benchee(tag, payloads, task, job)
    end)
  end

  defp run_benchee(tag, payloads, task, job) do
    Benchee.run(
      job,
      inputs: payloads,
      save: [
        path: Path.join(["./benchmark/output/benchee", "#{task}-#{tag}.benchee"]),
        tag: "#{task}-#{tag}"
      ],
      load: ["./benchmark/output/benchee/#{task}*.benchee"],
      time: 5,
      memory_time: 2,
      reduction_time: 2,
      formatters: [
        {Benchee.Formatters.HTML, file: "benchmark/output/html/#{task}-#{tag}.html"},
        Benchee.Formatters.Console
      ]
    )
  end

  defp get_tasks(opts) do
    case Keyword.get(opts, :task, nil) do
      nil -> [:encode, :decode]
      "encode" -> [:encode]
      "decode" -> [:decode]
    end
  end

  defp get_tag(opts) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%H%M%S")

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
