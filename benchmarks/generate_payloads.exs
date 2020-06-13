defmodule Protox.Benchmarks do
  @external_resource "./benchmarks/benchmarks.proto"
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
  xsmall: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 1, 4, 128),
  small: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 2, 128, 512),
  medium: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 3, 512, 2048),
  large: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 5, 2048, 8192),
  xlarge: Protox.GeneratePayloads.generate(Protox.Benchmarks.Upper, 10, 8192, 262_144),
  handmade: Protox.GeneratePayloads.handmade()
}

"./benchmarks/payloads.bin"
|> File.open!([:write])
|> IO.binwrite(:erlang.term_to_binary(payloads))
|> File.close()
