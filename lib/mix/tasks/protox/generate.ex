defmodule Mix.Tasks.Protox.Generate do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, files, []} <-
           OptionParser.parse(args,
             strict: [output_path: :string, include_path: :string, multiple_files: :boolean]
           ),
         {:ok, output_path} <- Keyword.fetch(options, :output_path),
         include_path <- Keyword.get(options, :include_path),
         multiple_files <- Keyword.get(options, :multiple_files, false) do
      files
      |> Protox.generate_module_code(output_path, multiple_files, include_path)
      |> Enum.each(&Protox.generate_file/1)
    else
      err ->
        IO.puts("Failed to generate code: #{inspect(err)}")
        :error
    end
  end
end
