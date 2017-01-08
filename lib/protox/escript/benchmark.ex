defmodule Protox.Escript.Benchmark do

  # import ExProf.Macro

  @moduledoc false

  defmodule Defs do
    @external_resource "./benchmarks/benchmark_messages_proto2.proto"
    @external_resource "./benchmarks/benchmark_messages_proto3.proto"
    @external_resource "./benchmarks/benchmarks.proto"

    use Protox, files: [
      "./benchmarks/benchmark_messages_proto2.proto",
      "./benchmarks/benchmark_messages_proto3.proto",
      "./benchmarks/benchmarks.proto",
    ],
    namespace: Protox
  end


  def run() do
    Path.wildcard("./benchmarks/dataset.*.pb")
    |> Enum.each(&benchmark/1)
  end


  # def profile() do
  #   profile do
  #     run()
  #   end
  # end


  # -- Private


  defp get_type("benchmarks.proto2.GoogleMessage1"), do: Protox.Benchmarks.Proto2.GoogleMessage1
  defp get_type("benchmarks.proto3.GoogleMessage1"), do: Protox.Benchmarks.Proto3.GoogleMessage1


  defp benchmark(file) do
    dataset = file |> File.read!() |> Protox.Benchmarks.BenchmarkDataset.decode!()
    ty = get_type(dataset.message_name)
    IO.puts ">>> #{inspect ty}"

    {nb_bytes, time} = decode_benchmark(ty, dataset.payload)
    seconds = time / 1000
    speed = (nb_bytes / 1024 / 1024) / seconds
    IO.puts "Decode: #{nb_bytes} bytes in #{time} ms: #{speed |> Float.round(3)} MB/s"

    {nb_bytes, time} = encode_benchmark(ty, dataset.payload)
    seconds = time / 1000
    speed = (nb_bytes / 1024 / 1024) / seconds
    IO.puts "Encode: #{nb_bytes} bytes in #{time} ms: #{speed |> Float.round(3)} MB/s"

    IO.puts ""
  end


  defp decode_benchmark(ty, payloads) do
    t0 = System.monotonic_time(:milliseconds)
    nb_bytes = Task.async(fn -> do_decode_benchmark(0, 30, ty, payloads) end)
               |> Task.await()
    t1 = System.monotonic_time(:milliseconds)

    {nb_bytes, t1 - t0}
  end


  defp do_decode_benchmark(total, 0, _, _) do
    total
  end
  defp do_decode_benchmark(total, counter, ty, payloads) do
    payloads
    |> Enum.reduce(total,
        fn (payload, acc) ->
          ty.decode(payload)
          acc + byte_size(payload)
        end)
    |> do_decode_benchmark(counter - 1, ty, payloads)
  end


  defp encode_benchmark(ty, payloads) do
    payloads_msg = Enum.map(payloads, fn payload -> ty.decode!(payload) end)

    t0 = System.monotonic_time(:milliseconds)
    nb_bytes = Task.async(fn -> do_encode_benchmark(0, 30, ty, payloads_msg) end)
               |> Task.await()
    t1 = System.monotonic_time(:milliseconds)

    {nb_bytes, t1 - t0}
  end


  defp do_encode_benchmark(total, 0, _, _) do
    total
  end
  defp do_encode_benchmark(total, counter, ty, payloads_msg) do
    payloads_msg
    |> Enum.reduce(total,
        fn (msg, acc) ->
          encoded = Protox.Encode.encode(msg) |> :erlang.iolist_to_binary()
          acc + byte_size(encoded)
        end)
    |> do_encode_benchmark(counter - 1, ty, payloads_msg)
  end

end
