defmodule Mix.Tasks.Protox.Benchmark.Run do
  @moduledoc false

  use Mix.Task

  @options [
    prefix: :string
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, _argv, []} <- OptionParser.parse(args, strict: @options),
         prefix <- Keyword.get(opts, :prefix, nil),
         tag <- get_tag(prefix),
         payloads <- get_payloads("./benchmark/benchmark_payloads.bin") do
      IO.puts("tag=#{tag}\n")

      Benchee.run(
        %{
          "decode" => fn input ->
            Enum.map(input, fn {msg, _size, bytes} -> msg.__struct__.decode!(bytes) end)
          end,
          "encode" => fn input ->
            Enum.map(input, fn {msg, _size, _bytes} -> msg.__struct__.encode!(msg) end)
          end
        },
        inputs: payloads,
        save: [
          path: Path.join(["./benchmark", "#{tag}.benchee"]),
          tag: "#{tag}"
        ],
        load: ["./benchmark/*.benchee"],
        time: 10,
        memory_time: 2,
        formatters: [
          {Benchee.Formatters.HTML, file: "benchmark/output/#{tag}.html"},
          Benchee.Formatters.Console
        ]
      )
    else
      err ->
        IO.puts(:stderr, "Error: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  defp get_tag(prefix) do
    {hash, 0} = System.cmd("git", ["rev-parse", "--short", "HEAD"])
    elixir_version = System.version()

    erlang_version =
      [:code.root_dir(), "releases", :erlang.system_info(:otp_release), "OTP_VERSION"]
      |> Path.join()
      |> File.read!()
      |> String.trim()

    tag = [elixir_version, erlang_version, hash]

    tag =
      case prefix do
        nil -> tag
        prefix -> [prefix | tag]
      end

    tag
    |> Enum.map(&String.trim/1)
    |> Enum.join("-")
  end

  def get_payloads(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
