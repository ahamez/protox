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

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {opts, files, []} <-
           OptionParser.parse(args,
             strict: [
               output_path: :string,
               include_path: :keep,
               namespace: :string,
               multiple_files: :boolean,
               keep_unknown_fields: :boolean
             ]
           ),
         {:ok, output_path} <- Keyword.fetch(opts, :output_path),
         {include_paths, opts} = pop_values(opts, :include_path),
         {multiple_files, opts} = Keyword.pop(opts, :multiple_files, false),
         {:ok, files_content} <-
           generate(files, output_path, multiple_files, include_paths, opts) do
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

  # Custom implementation as Keyword.pop_values/2 is only available since Elixir 1.10
  defp pop_values(opts, key) do
    {values, new_opts} =
      Enum.reduce(opts, {[], []}, fn
        {^key, value}, {values, new_opts} -> {[value | values], new_opts}
        {key, value}, {values, new_opts} -> {values, [{key, value} | new_opts]}
      end)

    {Enum.reverse(values), Enum.reverse(new_opts)}
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
