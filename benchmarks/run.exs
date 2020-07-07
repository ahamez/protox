# ----------------------------------------------------------------------------------------------- #

tags =
  with {options, _, []} <-
         OptionParser.parse(System.argv(), strict: [lib: :string, tags: :string]),
       {:ok, lib} <- Keyword.fetch(options, :lib) do
    Code.compile_file(lib)

    case Keyword.get(options, :tags) do
      nil -> :all
      tags -> tags |> String.split(",") |> Enum.map(&String.to_atom(&1))
    end
  else
    _ ->
      IO.puts("Missing lib argument")
      System.halt(0)
  end

# ----------------------------------------------------------------------------------------------- #

defmodule Protox.Benchmarks do
  use Protox, files: ["./benchmarks/benchmarks.proto"], namespace: Protox.Benchmarks
end

# ----------------------------------------------------------------------------------------------- #

defmodule Protox.Benchmarks.Data do
  def inputs(path, tags) do
    filter =
      case tags do
        :all -> fn _ -> true end
        tags -> fn {size, _payloads} -> size in tags end
      end

    decode =
      path
      |> File.read!()
      |> :erlang.binary_to_term()
      |> Enum.filter(&filter.(&1))
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
      |> Enum.filter(&filter.(&1))
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

# ----------------------------------------------------------------------------------------------- #

IO.puts("Will run benchmarks: #{inspect(tags)}")
{decode_inputs, encode_inputs} = Protox.Benchmarks.Data.inputs("./benchmarks/payloads.bin", tags)

# ----------------------------------------------------------------------------------------------- #

{head, 0} = System.cmd("git", ["symbolic-ref", "--short", "HEAD"])
{hash, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
tag = "#{String.trim(head)}-#{String.trim(hash)}"

# ----------------------------------------------------------------------------------------------- #

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
  save: [path: Path.join(["./benchmarks", "#{tag}_#{Protox.Benchmarks.Run.decode_file_name()}"])],
  time: 10,
  memory_time: 2
)

# ----------------------------------------------------------------------------------------------- #

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
  save: [path: Path.join(["./benchmarks", "#{tag}_#{Protox.Benchmarks.Run.encode_file_name()}"])],
  time: 10,
  memory_time: 2
)

# ----------------------------------------------------------------------------------------------- #
