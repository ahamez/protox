# ----------------------------------------------------------------------------------------------- #

opts =
  with {options, _, []} <-
         OptionParser.parse(System.argv(),
           strict: [lib: :string, selector: :string, tag: :string]
         ),
       {:ok, lib} <- Keyword.fetch(options, :lib) do
    Code.compile_file(lib)

    selector =
      case Keyword.get(options, :selector) do
        nil -> :all
        selector -> selector |> String.split(",") |> Enum.map(&String.to_atom(&1))
      end

    prefix =
      case Keyword.get(options, :tag) do
        nil -> ""
        prefix -> "#{prefix}-"
      end

    %{selector: selector, prefix: prefix}
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
  def inputs(path, selector) do
    filter =
      case selector do
        :all -> fn _ -> true end
        selector -> fn {size, _payloads} -> size in selector end
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

IO.puts("Will run benchmarks: #{inspect(opts.selector)}")

{decode_inputs, encode_inputs} =
  Protox.Benchmarks.Data.inputs("./benchmarks/payloads.bin", opts.selector)

# ----------------------------------------------------------------------------------------------- #

{hash, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
elixir_version = System.version()

erlang_version =
  [:code.root_dir(), "releases", :erlang.system_info(:otp_release), "OTP_VERSION"]
  |> Path.join()
  |> File.read!()
  |> String.trim()

tag = "#{opts.prefix}#{elixir_version}-#{erlang_version}-#{String.trim(hash)}"

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
  save: [
    path: Path.join(["./benchmarks", "#{tag}_#{Protox.Benchmarks.Run.decode_file_name()}"]),
    tag: "#{tag}"
  ],
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
  save: [
    path: Path.join(["./benchmarks", "#{tag}_#{Protox.Benchmarks.Run.encode_file_name()}"]),
    tag: "#{tag}"
  ],
  time: 10,
  memory_time: 2
)

# ----------------------------------------------------------------------------------------------- #
