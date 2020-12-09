defmodule Mix.Tasks.Protox.Generate do
  @moduledoc """
  Generate Elixir code from `.proto` files.

  Example:
  `mix protox.generate --output-path=lib/message.ex --include-path=. message.proto`

  The generated file will be usable in any project as long as protox is declared
  in the dependencies (the generated file still needs functions from the protox runtime).

  If you have large protobuf files, you can use the `--multiple-files` option to generate
  one file per module.

  Finally, you can pass the option `--keep-unknown-fields=false` to remove support of
  unknown fields.
  """
  @shortdoc "Generate Elixir code from Protobuf definitions"

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, files, []} <-
           OptionParser.parse(args,
             strict: [
               output_path: :string,
               include_path: :string,
               multiple_files: :boolean,
               keep_unknown_fields: :boolean
             ]
           ),
         {:ok, output_path} <- Keyword.fetch(opts, :output_path) do
      {include_path, opts} = Keyword.pop(opts, :include_path)
      {multiple_files, opts} = Keyword.pop(opts, :multiple_files, false)

      files
      |> Protox.generate_module_code(output_path, multiple_files, include_path, opts)
      |> Enum.each(&generate_file/1)
    else
      err ->
        IO.puts("Failed to generate code: #{inspect(err)}")
        :error
    end
  end

  defp generate_file(%Protox.FileContent{name: file_name, content: content}) do
    File.write!(file_name, content)
  end
end
