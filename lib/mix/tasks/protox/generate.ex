defmodule Mix.Tasks.Protox.Generate do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, files, []} <-
           OptionParser.parse(args, strict: [output_path: :string, include_path: :string]),
         {:ok, output_path} <- Keyword.fetch(options, :output_path),
         include_path <- Keyword.get(options, :include_path) do
      generate_code(files, output_path, include_path)
    else
      err ->
        IO.puts("Failed to generate code: #{inspect(err)}")
        :error
    end
  end

  defp generate_code(files, output_path, include_path) do
    code = Protox.generate_code(files, include_path)
    File.write!(output_path, code)
  end
end
