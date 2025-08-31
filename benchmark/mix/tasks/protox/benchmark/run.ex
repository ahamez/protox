defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  alias Benchee.Formatters.Console

  @options [
    task: :string,
    warmup: :integer,
    time: :integer,
    memory_time: :integer,
    reduction_time: :integer
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, argv, []} <- OptionParser.parse(args, strict: @options),
         tasks = get_tasks(opts),
         benchee_cfg = get_benchee_config(opts),
         {:ok, tag} <- get_tag(argv) do
      payloads = get_payloads("./benchmark/benchmark_payloads.bin")
      run_benchee_tasks(tag, payloads, tasks, benchee_cfg)
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp run_benchee_tasks(tag, payloads, tasks, benchee_cfg) do
    Enum.each(tasks, fn task ->
      job =
        case task do
          :encode ->
            %{
              encode: fn input ->
                Enum.each(input, fn {msg, _size, _bytes} -> msg.__struct__.encode!(msg) end)
              end
            }

          :decode ->
            %{
              decode: fn input ->
                Enum.each(input, fn {msg, _size, bytes} -> msg.__struct__.decode!(bytes) end)
              end
            }
        end

      run_benchee(tag, payloads, task, job, benchee_cfg)
    end)
  end

  defp run_benchee(tag, payloads, task, job, benchee_cfg) do
    Benchee.run(
      job,
      inputs: payloads,
      save: [
        path: Path.join(["./benchmark/output/benchee", "#{task}-#{tag}.benchee"]),
        tag: "#{task}-#{tag}"
      ],
      warmup: benchee_cfg.warmup,
      time: benchee_cfg.time,
      memory_time: benchee_cfg.memory_time,
      reduction_time: benchee_cfg.reduction_time,
      formatters: [Console]
    )
  end

  defp get_tasks(opts) do
    case Keyword.get(opts, :task, nil) do
      nil -> [:encode, :decode]
      "encode" -> [:encode]
      "decode" -> [:decode]
    end
  end

  defp get_benchee_config(opts) do
    %{
      warmup: Keyword.get(opts, :warmup, 2),
      time: Keyword.get(opts, :time, 5),
      memory_time: Keyword.get(opts, :memory_time, 2),
      reduction_time: Keyword.get(opts, :reduction_time, 2)
    }
  end

  defp get_tag([]), do: {:error, "No tag provided"}

  defp get_tag([tag]) do
    timestamp = DateTime.utc_now() |> Calendar.strftime("%H%M%S")

    {:ok, "#{timestamp}-#{tag}"}
  end

  defp get_tag([_ | _]), do: {:error, "Too many tags provided"}

  def get_payloads(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
