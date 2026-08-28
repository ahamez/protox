defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  alias Benchee.Formatters.Console
  alias Benchmarks.Proto2.GoogleMessage1
  alias Opentelemetry.Proto.Trace.V1.TracesData

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
         {:ok, tasks} <- get_tasks(opts),
         benchee_cfg = get_benchee_config(opts),
         {:ok, tag} <- get_tag(argv) do
      payloads = get_payloads("./benchmark/benchmark_payloads.bin")
      verify_payloads(payloads)
      run_benchee_tasks(tag, payloads, tasks, benchee_cfg)
    else
      err ->
        Mix.shell().error("Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp run_benchee_tasks(tag, payloads, tasks, benchee_cfg) do
    Enum.each(tasks, fn task ->
      run_benchee(tag, build_inputs(payloads, task), task, job(task), benchee_cfg)
    end)
  end

  # The module is taken from the input rather than from `msg.__struct__` so that the
  # measured region contains the codec call and nothing else.
  defp job(:encode) do
    %{encode: fn {module, msgs} -> Enum.each(msgs, &module.encode!/1) end}
  end

  defp job(:decode) do
    %{decode: fn {module, binaries} -> Enum.each(binaries, &module.decode!/1) end}
  end

  # Benchee keeps the order of a list of inputs (a map would be reordered by term
  # order), so sorting by corpus size makes the report read smallest to largest.
  defp build_inputs(payloads, task) do
    payloads
    |> Enum.sort_by(fn {_module, samples} -> total_size(samples) end)
    |> Enum.map(fn {module, samples} -> {input_name(module), {module, inputs_for(samples, task)}} end)
  end

  defp inputs_for(samples, :encode), do: Enum.map(samples, fn {msg, _size, _bytes} -> msg end)
  defp inputs_for(samples, :decode), do: Enum.map(samples, fn {_msg, _size, bytes} -> bytes end)

  defp total_size(samples) do
    samples
    |> Stream.map(fn {_msg, size, _bytes} -> size end)
    |> Enum.sum()
  end

  # Benchee matches scenarios across saved suites by input name, so these have to be
  # unique. The two Google datasets share a message name and differ only by their
  # proto2/proto3 package, which the last-segment fallback below cannot tell apart.
  @input_names %{
    GoogleMessage1 => "google_message1_proto2",
    Benchmarks.Proto3.GoogleMessage1 => "google_message1_proto3",
    TracesData => "otel_traces_data",
    Prometheus.WriteRequest => "prometheus_write_request"
  }

  defp input_name(module) do
    case Map.fetch(@input_names, module) do
      {:ok, name} -> name
      :error -> derive_input_name(module)
    end
  end

  defp derive_input_name(module) do
    case Module.split(module) do
      ["Protox", "Benchmark", "Synthetic" <> count, "Message"] ->
        "synthetic_#{count}"

      ["Protox", "Benchmark", name, "Message"] ->
        Macro.underscore(name)

      parts ->
        parts
        |> List.last()
        |> Macro.underscore()
    end
  end

  # An optimization that silently drops fields would post excellent numbers, so the
  # corpus is re-encoded once, outside the measured region, and checked against the
  # sizes recorded when it was generated.
  #
  # Known limitation: this only catches size-changing corruption, and only on the
  # encoding side. Value-level correctness and the decoder are covered by `mix test`
  # and `mix protox.conformance`. Upgrade path if that becomes insufficient: compare
  # `module.decode!(bytes)` against `msg` here as well, at the cost of a slower start.
  defp verify_payloads(payloads) do
    Enum.each(payloads, fn {module, samples} ->
      Enum.each(samples, fn {msg, size, _bytes} -> verify_sample(module, msg, size) end)
    end)
  end

  defp verify_sample(module, msg, size) do
    {iodata, reported_size} = module.encode!(msg)
    encoded_size = IO.iodata_length(iodata)

    cond do
      encoded_size != size ->
        Mix.raise("#{inspect(module)}: encoded #{encoded_size} bytes, corpus expects #{size}")

      reported_size != size ->
        Mix.raise("#{inspect(module)}: encode! reported #{reported_size} bytes, corpus expects #{size}")

      true ->
        :ok
    end
  end

  defp run_benchee(tag, inputs, task, job, benchee_cfg) do
    Benchee.run(
      job,
      inputs: inputs,
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
    case Keyword.get(opts, :task) do
      nil -> {:ok, [:encode, :decode]}
      "encode" -> {:ok, [:encode]}
      "decode" -> {:ok, [:decode]}
      other -> {:error, ~s(Unknown task #{inspect(other)}, expected "encode" or "decode")}
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
    timestamp = Calendar.strftime(DateTime.utc_now(), "%H%M%S")

    {:ok, "#{timestamp}-#{tag}"}
  end

  defp get_tag([_tag | _rest]), do: {:error, "Too many tags provided"}

  def get_payloads(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
