defmodule Protox.Benchmarks do
  use Protox, files: ["./benchmarks/benchmarks.proto"], namespace: Protox.Benchmarks
end

Code.compile_file("./test/random_init.exs")
Code.compile_file("./benchmarks/handmade_payloads.exs")

defmodule Protox.GeneratePayloads do
  use PropCheck

  def generate(mod, size, min_sz, max_sz, nb \\ 1000) do
    IO.puts("Generating for size=#{size}, min_sz=#{min_sz}, max_sz=#{max_sz}")

    gen =
      let fields <- Protox.RandomInit.generate_fields(mod) do
        Protox.RandomInit.generate_struct(mod, fields)
      end

    Stream.repeatedly(fn ->
      {:ok, msg} = :proper_gen.pick(gen, size)
      msg |> Protox.Encode.encode!() |> :binary.list_to_bin()
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
      {mod, msg |> Protox.Encode.encode!() |> :binary.list_to_bin()}
    end)
  end
end

payloads = %{
  upper_xsmall: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 1, 4, 128),
  upper_small: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 2, 128, 512),
  upper_medium: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 3, 512, 2048),
  upper_large: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 5, 2048, 8192),
  upper_xlarge: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 10, 8192, 262_144),
  sub_xsmall: Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 1, 4, 128),
  sub_small: Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 2, 128, 256),
  sub_medium: Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 10, 256, 512),
  sub_large: Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 20, 512, 1024),
  sub_xlarge: Protox.GeneratePayloads.generate(Protox.Benchmarks.Sub, 50, 1024, 2048),
  handmade: Protox.GeneratePayloads.handmade()
}

"./benchmarks/payloads.bin"
|> File.open!([:write])
|> IO.binwrite(:erlang.term_to_binary(payloads))
|> File.close()
