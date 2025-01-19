defmodule Mix.Tasks.Protox.Generate do
  @moduledoc """
  Generate Elixir code from `.proto` files.

  Example:
  `mix protox.generate --output-path=lib/message.ex --include-path=. message.proto`

  The generated file will be usable in any project as long as protox is declared
  in the dependencies (the generated file still needs functions from the protox runtime).

  You can use the `--namespace` option to prepend a namespace to all generated modules.

  If you have large protobuf files, you can use the `--multiple-files` option to generate
  one file per module.

  Finally, you can pass the option `--keep-unknown-fields=false` to remove support of
  unknown fields.
  """
  @shortdoc "Generate Elixir code from Protobuf definitions"

  use Mix.Task

  @options [
    output_path: :string,
    include_path: :keep,
    namespace: :string,
    multiple_files: :boolean,
    generate: :string
  ]

  @default_generate_opt_all []
  @default_generate_opt_none []
  @map_generate_opts %{}

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, files, []} <- OptionParser.parse(args, strict: @options),
         {:ok, output_path} <- Keyword.fetch(opts, :output_path),
         {include_paths, opts} = Keyword.pop_values(opts, :include_path),
         {multiple_files, opts} = Keyword.pop(opts, :multiple_files, false),
         {generate_opts, opts} = Keyword.pop(opts, :generate, "all"),
         opts <- transform_generate_opts(generate_opts, opts),
         {:ok, files_content} <- generate(files, output_path, multiple_files, include_paths, opts) do
      Enum.each(files_content, &generate_file/1)
    else
      err ->
        IO.puts(:stderr, "Failed to generate code: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  # -- Private

  defp transform_generate_opts("all", opts), do: opts ++ @default_generate_opt_all
  defp transform_generate_opts("none", opts), do: opts ++ @default_generate_opt_none

  defp transform_generate_opts(generate_opts, opts) when is_binary(generate_opts) do
    generate_opts
    |> String.split(",")
    |> Enum.map(&Map.fetch!(@map_generate_opts, &1))
    |> Enum.concat(opts)
  end

  defp generate_file(%Protox.Generate.FileContent{name: file_name, content: content}) do
    File.write!(file_name, content)
  end

  defp generate(files, output_path, multiple_files, include_paths, opts) do
    Protox.Generate.generate_module_code(
      files,
      Path.expand(output_path),
      multiple_files,
      include_paths,
      opts
    )
  end
end
