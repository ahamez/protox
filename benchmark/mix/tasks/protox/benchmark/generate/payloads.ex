defmodule Mix.Tasks.Protox.Benchmark.Generate.Payloads do
  @moduledoc false

  use Mix.Task
  import StreamData

  alias ProtobufTestMessages.Proto3.TestAllTypesProto3

  require Logger

  @nb_samples 10

  @impl Mix.Task
  @spec run(any) :: any
  def run(_args) do
    with {:ok, modules} <- get_benchmark_modules(),
         {:ok, payloads} <- generate_payloads(modules),
         {:ok, file} <- File.open("./benchmark/benchmark_payloads.bin", [:write]) do
      IO.binwrite(file, :erlang.term_to_binary(payloads))
      File.close(file)
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp get_benchmark_modules() do
    case :application.get_key(:protox, :modules) do
      {:ok, modules} ->
        modules =
          Enum.filter(modules, fn mod ->
            match?(["Protox", "Benchmark", _, "Message"], Module.split(mod))
          end)

        modules = [TestAllTypesProto3 | modules]

        Logger.info("Modules: #{inspect(modules)}")

        {:ok, modules}

      :undefined ->
        :error
    end
  end

  defp generate_payloads(modules) do
    payloads_async =
      for module <- modules, into: %{} do
        {module, fn -> generate_payload(module) end}
      end

    payloads =
      payloads_async
      |> Task.async_stream(fn {name, gen} -> {name, gen.()} end, timeout: :infinity)
      |> Map.new(fn {:ok, {name, payloads}} -> {name, payloads} end)

    {:ok, payloads}
  end

  defp generate_payload(mod) do
    Logger.info("Generating payload for #{mod}")

    gen =
      bind(Protox.RandomInit.generate_fields(mod), fn fields ->
        constant(Protox.RandomInit.generate_struct(mod, fields))
      end)

    Stream.repeatedly(fn -> gen |> resize(5) |> Enum.at(0) end)
    |> Stream.map(fn msg ->
      {msg, msg |> Protox.encode!() |> elem(0) |> IO.iodata_to_binary()}
    end)
    |> Stream.reject(fn {_msg, bytes} -> byte_size(bytes) == 0 end)
    |> Stream.reject(fn {_msg, bytes} -> byte_size(bytes) > 16_384 * 16 end)
    |> Stream.map(fn {msg, bytes} -> {msg, byte_size(bytes), bytes} end)
    |> Stream.each(fn _ -> Logger.info("Payload generated for #{mod}") end)
    |> Enum.take(@nb_samples)
  end
end
