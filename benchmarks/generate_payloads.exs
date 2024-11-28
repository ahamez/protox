defmodule Protox.Benchmarks do
  use Protox, files: ["./benchmarks/benchmarks.proto"], namespace: Protox.Benchmarks
end

Code.compile_file("./test/support/random_init.ex")
Code.compile_file("./benchmarks/handmade_payloads.exs")

defmodule Protox.GeneratePayloads do
  use PropCheck

  def generate(mod, size, min_sz, max_sz, nb \\ 100) do
    IO.puts("Generating for size=#{size}, min_sz=#{min_sz}, max_sz=#{max_sz}")

    gen =
      let fields <- Protox.RandomInit.generate_fields(mod) do
        Protox.RandomInit.generate_struct(mod, fields)
      end

    Stream.repeatedly(fn ->
      {:ok, msg} = :proper_gen.pick(gen, size)
      msg |> Protox.encode!() |> :binary.list_to_bin()
    end)
    |> Stream.reject(fn bytes ->
      byte_size(bytes) == 0 or byte_size(bytes) < min_sz or byte_size(bytes) >= max_sz
    end)
    |> Stream.map(fn payload ->
      {mod |> Module.split() |> List.last(), payload}
    end)
    |> Enum.take(nb)
  end

  def handmade() do
    Enum.map(Protox.Benchmarks.HandmadePayloads.payloads(), fn msg ->
      mod = msg.__struct__ |> Module.split() |> List.last()
      {mod, msg |> Protox.encode!() |> :binary.list_to_bin()}
    end)
  end
end

payloads_async = %{
  upper_xsmall: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 1, 4, 128) end,
  upper_small: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 2, 128, 512) end,
  upper_medium: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 3, 512, 2048) end,
  upper_large: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 5, 2048, 8192) end,
  upper_xlarge: fn ->
    Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 10, 8192, 262_144)
  end,
  sub_xsmall: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 1, 4, 128) end,
  sub_small: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 2, 128, 256) end,
  sub_medium: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 10, 256, 512) end,
  sub_large: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 20, 512, 1024) end,
  sub_xlarge: fn -> Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 50, 1024, 2048) end,
  handmade: fn -> Protox.GeneratePayloads.handmade() end
}

payloads =
  payloads_async
  |> Task.async_stream(fn {name, gen} -> {name, gen.()} end, timeout: :infinity)
  |> Stream.map(fn {:ok, {name, payloads}} -> {name, payloads} end)
  |> Map.new()

"./benchmarks/payloads.bin"
|> File.open!([:write])
|> IO.binwrite(:erlang.term_to_binary(payloads))
|> File.close()
