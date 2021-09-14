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
        namespace_or_nil \\ nil,
        opts \\ []
      )
      when is_list(files) and is_binary(output_path) and is_boolean(multiple_files) do
    paths =
      case include_paths do
        [] -> nil
        _ -> Enum.map(include_paths, &Path.expand/1)
      end

    {:ok, file_descriptor_set} =
      files
      |> Enum.map(&Path.expand/1)
      |> Protox.Protoc.run(paths)

    %{enums: enums, messages: messages} =
      Protox.Parse.parse(file_descriptor_set, namespace_or_nil)

    code = quote do: unquote(Protox.Define.define(enums, messages, opts))

    if multiple_files do
      multiple_file_content(output_path, code)
    else
      single_file_content(output_path, code)
    end
  end

  # -- Private

  defp single_file_content(output_path, code) do
    [
      %FileContent{
        name: output_path,
        content: generate_file_content(code)
      }
    ]
  end

  defp multiple_file_content(output_path, code) do
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
