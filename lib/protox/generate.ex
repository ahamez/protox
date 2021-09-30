defmodule Protox.Generate do
  @moduledoc false

  defmodule FileContent do
    @moduledoc false
    defstruct([:name, :content])
  end

  def generate_module_code(
        files,
        output_path,
        multiple_files,
        include_paths,
        opts \\ []
      )
      when is_list(files) and is_binary(output_path) and is_boolean(multiple_files) do
    paths =
      case include_paths do
        [] -> nil
        _ -> Enum.map(include_paths, &Path.expand/1)
      end

    case launch_protoc(files, paths) do
      {:ok, file_descriptor_set} ->
        %{enums: enums, messages: messages} = Protox.Parse.parse(file_descriptor_set, opts)
        code = quote do: unquote(Protox.Define.define(enums, messages, opts))
        {:ok, generate_files(output_path, code, multiple_files)}

      {:error, msg} ->
        {:error, msg}
    end
  end

  # -- Private

  defp launch_protoc(files, paths) do
    files
    |> Enum.map(&Path.expand/1)
    |> Protox.Protoc.run(paths)
  end

  defp generate_files(output_path, code, false = _muliple_files) do
    [
      %FileContent{
        name: output_path,
        content: generate_file_content(code)
      }
    ]
  end

  defp generate_files(output_path, code, true = _muliple_files) do
    Enum.map(code, fn {:defmodule, _, [module_name | _]} = module_code ->
      snake_module_name =
        module_name |> to_string() |> String.replace(".", "") |> Macro.underscore()

      %FileContent{
        name: Path.join(output_path, snake_module_name <> ".ex"),
        content: generate_file_content(module_code)
      }
    end)
  end

  defp generate_file_content(code) do
    code_str = Macro.to_string(code)

    formatted_code =
      try do
        Code.format_string!(code_str)
      rescue
        _ -> code_str
      end

    [
      "# credo:disable-for-this-file\n",
      formatted_code
    ]
  end
end
