defmodule Mix.Tasks.Protox.Generate do
  @moduledoc false

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
