defmodule Mix.Tasks.Protox.Benchmark.Generate.Payloads do
  @moduledoc false

  use Mix.Task

  alias Benchmarks.BenchmarkDataset
  alias Benchmarks.Proto2.GoogleMessage1
  alias Opentelemetry.Proto.Trace.V1.TracesData
  alias Prometheus.WriteRequest
  alias ProtobufTestMessages.Proto3.TestAllTypesProto3
  alias Protox.Benchmark.Ascii
  alias StreamData

  require Logger

  @output "./benchmark/benchmark_payloads.bin"

  @nb_samples 10
  @max_payload_size 16_384 * 16

  # StreamData's size parameter. The real-world schemas need a much larger one: at the
  # default a generated TracesData or WriteRequest comes out under 300 bytes, smaller
  # than the smallest synthetic message, which would measure per-call overhead instead
  # of the repeated-message and attribute-list paths they were added to cover.
  @default_size 5
  @real_world_size 40
  @real_world_modules [TracesData, WriteRequest]

  # Real captured payloads from Google's benchmark suite, as opposed to everything else
  # here, which is generated. See benchmark/protos/vendor/README.md.
  @datasets [
    {"./benchmark/protos/vendor/google/dataset.google_message1_proto2.pb", GoogleMessage1},
    {"./benchmark/protos/vendor/google/dataset.google_message1_proto3.pb", Benchmarks.Proto3.GoogleMessage1}
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(_args) do
    with {:ok, modules} <- get_benchmark_modules(),
         {:ok, generated} <- generate_payloads(modules) do
      # The whole corpus is built before the output is opened: loading a vendored dataset
      # can raise, and opening the file first would truncate the existing corpus before
      # that happened, leaving an empty artifact behind after a failed regeneration.
      payloads = Map.merge(generated, load_datasets())

      # Compressed because the decoded structs dominate the term: a Synthetic200 message
      # carries all 200 keys at every nesting level even when they hold defaults, so the
      # uncompressed corpus is ~100x the size of the encoded bytes it represents.
      File.write!(@output, :erlang.term_to_binary(payloads, compressed: 9))
    else
      err ->
        Mix.shell().error("Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp get_benchmark_modules() do
    case :application.get_key(:protox, :modules) do
      {:ok, modules} ->
        modules =
          Enum.filter(modules, fn mod ->
            match?(["Protox", "Benchmark", _mod_name, "Message"], Module.split(mod))
          end)

        modules = [TestAllTypesProto3 | modules] ++ @real_world_modules

        Logger.info("Modules: #{inspect(modules)}")

        {:ok, modules}

      :undefined ->
        :error
    end
  end

  defp generate_payloads(modules) do
    payloads =
      modules
      |> Task.async_stream(fn module -> {module, generate_payload(module)} end, timeout: :infinity)
      |> Map.new(fn {:ok, {module, payloads}} -> {module, payloads} end)

    {:ok, payloads}
  end

  defp generate_payload(Ascii.Message = mod) do
    Logger.info("Generating payload for #{mod}")

    Enum.map(1..@nb_samples, fn n -> measure(mod, ascii_message(n)) end)
  end

  defp generate_payload(mod) do
    Logger.info("Generating payload for #{mod}")

    gen =
      StreamData.bind(Protox.RandomInit.generate_fields_values(mod), fn fields ->
        StreamData.constant(Protox.RandomInit.generate_struct(mod, fields))
      end)

    gen
    |> StreamData.resize(stream_data_size(mod))
    |> Stream.map(&measure(mod, &1))
    |> Stream.reject(fn {_msg, size, _bytes} -> size == 0 end)
    |> Stream.reject(fn {_msg, size, _bytes} -> size > @max_payload_size end)
    |> Stream.each(fn _msg -> Logger.info("Payload generated for #{mod}") end)
    |> Enum.take(@nb_samples)
  end

  defp stream_data_size(mod) when mod in @real_world_modules, do: @real_world_size
  defp stream_data_size(_mod), do: @default_size

  defp measure(mod, msg) do
    bytes =
      msg
      |> mod.encode!()
      |> elem(0)
      |> IO.iodata_to_binary()

    {msg, byte_size(bytes), bytes}
  end

  # The datasets ship one real payload each, wrapped in a BenchmarkDataset message.
  #
  # `size` is protox's own encoded size rather than `byte_size(bytes)`, which are not
  # always equal here: the captured proto3 payload contains explicitly-written default
  # values that proto3 semantics omit on re-encode (228 bytes in, 221 bytes out). Keeping
  # the captured bytes as the decode input preserves the realism the dataset was added
  # for, while `size` stays the value the benchmark's pre-run encode check needs.
  defp load_datasets() do
    Map.new(@datasets, fn {path, mod} ->
      Logger.info("Loading dataset #{path} for #{mod}")

      dataset =
        path
        |> File.read!()
        |> BenchmarkDataset.decode!()

      samples =
        Enum.map(dataset.payload, fn bytes ->
          msg = mod.decode!(bytes)
          {_msg, size, _reencoded} = measure(mod, msg)

          {msg, size, bytes}
        end)

      {mod, samples}
    end)
  end

  @ascii_alphabet ~c"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,;:!?-_/"

  defp ascii_message(n) do
    struct!(Ascii.Message,
      field_1: ascii_text(16 * n),
      field_2: ascii_text(32 * n),
      field_3: ascii_text(64 * n),
      field_4: ascii_text(8 * n),
      field_5: ascii_text(128 * n),
      field_6: Enum.map(1..n, fn i -> ascii_text(24 * i) end),
      field_7: Enum.map(1..n, fn i -> ascii_text(48 * i) end),
      field_8: ascii_sub(n),
      field_9: Enum.map(1..n, &ascii_sub/1)
    )
  end

  defp ascii_sub(n) do
    struct!(Ascii.Sub,
      field_1: ascii_text(12 * n),
      field_2: ascii_text(20 * n),
      field_3: Enum.map(1..n, fn i -> ascii_text(16 * i) end)
    )
  end

  defp ascii_text(length) do
    @ascii_alphabet
    |> Stream.cycle()
    |> Enum.take(length)
    |> List.to_string()
  end
end
