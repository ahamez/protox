defmodule Protox.Escript.Benchmark do

  # import ExProf.Macro

  @moduledoc false

  defmodule Defs do
    @moduledoc false

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
    "./benchmarks/dataset.*.pb"
    |> Path.wildcard()
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

    nb_bytes = payloads
               |> Enum.reduce(
                  0,
                  fn (payload, acc) ->
                    size = byte_size(payload)
                    acc + size * do_decode_benchmark(0, 300_000, ty, payload)
                  end)

    t1 = System.monotonic_time(:milliseconds)

    {nb_bytes, t1 - t0}
  end


  defp do_decode_benchmark(nb_processed, 0, _, _) do
    nb_processed
  end
  defp do_decode_benchmark(nb_processed, counter, ty, payload) do
    ty.decode(payload)
    do_decode_benchmark(nb_processed + 1, counter - 1, ty, payload)
  end


  defp encode_benchmark(ty, payloads) do
    payloads_msg = Enum.map(payloads, fn payload -> ty.decode!(payload) end)

    t0 = System.monotonic_time(:milliseconds)

    nb_bytes = payloads_msg
               |> Enum.reduce(
                  0,
                  fn (msg, acc) ->
                    size = msg
                           |> Protox.Encode.encode()
                           |> :erlang.iolist_to_binary()
                           |> byte_size()
                    acc + size * do_encode_benchmark(0, 300_000, ty, msg)
                  end)

    t1 = System.monotonic_time(:milliseconds)

    {nb_bytes, t1 - t0}
  end


  defp do_encode_benchmark(nb_processed, 0, _, _) do
    nb_processed
  end
  defp do_encode_benchmark(nb_processed, counter, ty, msg) do
    Protox.Encode.encode(msg)
    do_encode_benchmark(nb_processed + 1, counter - 1, ty, msg)
  end

end
