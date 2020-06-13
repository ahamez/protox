# -------------------------------------------------------------------------------------------------#

with {options, _, []} <- OptionParser.parse(System.argv(), strict: [lib: :string]),
     {:ok, lib} <- Keyword.fetch(options, :lib) do
  Code.compile_file(lib)
else
  _ ->
    IO.puts("Missing lib argument")
    System.halt(0)
end

# -------------------------------------------------------------------------------------------------#

defmodule Protox.Benchmarks do
  @external_resource "./benchmarks/benchmarks.proto"
  use Protox, files: ["./benchmarks/benchmarks.proto"], namespace: Protox.Benchmarks
end

# -------------------------------------------------------------------------------------------------#

defmodule Protox.Benchmarks.Data do
  def inputs(path) do
    decode =
      path
      |> File.read!()
      |> :erlang.binary_to_term()
      |> Enum.into(%{}, fn {size, payloads} ->
        payloads =
          Enum.map(payloads, fn {mod, bytes} ->
            {mod, bytes}
          end)

        {"#{Atom.to_string(size)}", payloads}
      end)

    encode =
      path
      |> File.read!()
      |> :erlang.binary_to_term()
      |> Enum.into(%{}, fn {size, payloads} ->
        payloads =
          Enum.map(payloads, fn {mod, bytes} ->
            Protox.Benchmarks.Run.decode({mod, bytes})
          end)

        {"#{Atom.to_string(size)}", payloads}
      end)

    {decode, encode}
  end
end

# -------------------------------------------------------------------------------------------------#

{decode_inputs, encode_inputs} = Protox.Benchmarks.Data.inputs("./benchmarks/payloads.bin")

# -------------------------------------------------------------------------------------------------#

Benchee.run(
  %{
    Protox.Benchmarks.Run.decode_name() => fn input ->
      Enum.map(input, &Protox.Benchmarks.Run.decode(&1))
    end
  },
  inputs: decode_inputs,
  formatters: [
    Benchee.Formatters.Console
  ],
  save: [path: Path.join(["./benchmarks", Protox.Benchmarks.Run.decode_file_name()])],
  time: 10,
  memory_time: 2
)

# -------------------------------------------------------------------------------------------------#

Benchee.run(
  %{
    Protox.Benchmarks.Run.encode_name() => fn input ->
      Enum.map(input, &Protox.Benchmarks.Run.encode(&1))
    end
  },
  inputs: encode_inputs,
  formatters: [
    Benchee.Formatters.Console
  ],
  save: [path: Path.join(["./benchmarks", Protox.Benchmarks.Run.encode_file_name()])],
  time: 10,
  memory_time: 2
)

# -------------------------------------------------------------------------------------------------#
