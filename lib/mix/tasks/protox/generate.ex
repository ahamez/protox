defmodule Mix.Tasks.Protox.Generate do
  @shortdoc "Generate Elixir code from Protobuf definitions"

  @moduledoc """
  Generate Elixir code from `.proto` files.

  Example:
  `mix protox.generate --output-path=lib/message.ex --include-path=. message.proto`

  The generated file will be usable in any project as long as protox is declared
  in the dependencies (the generated code still needs functions from the protox runtime).

  You can use the `--namespace` option to prepend a namespace to all generated modules.

  If you have large protobuf files, you can use the `--multiple-files` option to generate
  one file per module (it will leverage parallel compilation).
  """
  use Mix.Task

  @options [
    output_path: :string,
    include_path: :keep,
    namespace: :string,
    multiple_files: :boolean
  ]

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, files, []} <- OptionParser.parse(args, strict: @options),
         {:ok, output_path} <- Keyword.fetch(opts, :output_path),
         {include_paths, opts} = Keyword.pop_values(opts, :include_path),
         {multiple_files, opts} = Keyword.pop(opts, :multiple_files, false),
         {:ok, files_content} <-
           generate_code(files, output_path, multiple_files, include_paths, opts) do
      Enum.each(files_content, &generate_file/1)
    else
      err ->
        IO.puts(:stderr, "Failed to generate code: #{inspect(err)}")
        exit({:shutdown, 1})
    end
  end

  # -- Private

  defp generate_file(%Protox.Generate.FileContent{name: file_name, content: content}) do
    File.write!(file_name, content)
  end

  defp generate_code(files, output_path, multiple_files, include_paths, opts) do
    Protox.Generate.generate_module_code(
      files,
      Path.expand(output_path),
      multiple_files,
      include_paths,
      opts
    )
  end
end
