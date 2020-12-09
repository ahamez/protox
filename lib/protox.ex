defmodule Protox do
  @moduledoc ~S'''
  Use this module to generate the Elixir modules corresponding to a set of protobuf definitions.

  ## Examples
  From a set of files:
      defmodule Foo do
        use Protox,
          files: [
            "./defs/foo.proto",
            "./defs/bar.proto",
            "./defs/baz/fiz.proto",
          ]
      end

  From a string:
      defmodule Bar do
        use Protox,
          schema: """
          syntax = "proto3";

          message Baz {
          }

          message Foo {
            map<int32, Baz> b = 2;
          }
          """
      end

  The generated modules respect the package declaration. For instance, in the above example,
  both the `Fiz.Baz` and `Fiz.Foo` modules will be generated.

  See [README](readme.html) for detailed instructions.
  '''

  defmacro __using__(opts) do
    {opts, _} = Code.eval_quoted(opts)

    {namespace, opts} = get_namespace(opts)
    {path, opts} = get_path(opts)
    {files, opts} = get_files(opts)

    {:ok, file_descriptor_set} = Protox.Protoc.run(files, path)
    {enums, messages} = Protox.Parse.parse(file_descriptor_set, namespace)

    quote do
      unquote(make_external_resources(files))
      unquote(Protox.Define.define(enums, messages, opts))
    end
  end

  defp get_namespace(opts) do
    Keyword.pop(opts, :namespace)
  end

  defp get_path(opts) do
    case Keyword.pop(opts, :path) do
      {nil, opts} -> {nil, opts}
      {p, opts} -> {Path.expand(p), opts}
    end
  end

  defp get_files(opts) do
    case Keyword.pop(opts, :schema) do
      {<<text::binary>>, opts} ->
        filename = "#{Base.encode16(:crypto.hash(:sha, text))}.proto"
        filepath = [Mix.Project.build_path(), filename] |> Path.join() |> Path.expand()
        File.write!(filepath, text)
        {[filepath], opts}

      {nil, opts} ->
        {files, opts} = Keyword.pop(opts, :files)
        {Enum.map(files, &Path.expand/1), opts}
    end
  end

  defmodule FileContent do
    @moduledoc false
    defstruct([:name, :content])
  end

  def generate_module_code(files, output_path, multiple_files, include_path_or_nil, opts \\ [])
      when is_list(files) and is_binary(output_path) and is_boolean(multiple_files) do
    path =
      case include_path_or_nil do
        nil -> nil
        _ -> Path.expand(include_path_or_nil)
      end

    {:ok, file_descriptor_set} =
      files
      |> Enum.map(&Path.expand/1)
      |> Protox.Protoc.run(path)

    {enums, messages} = Protox.Parse.parse(file_descriptor_set, nil)

    code = quote do: unquote(Protox.Define.define(enums, messages, opts))

    if multiple_files do
      multiple_file_content(output_path, code)
    else
      single_file_content(output_path, code)
    end
  end

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

  defp make_external_resources(files) do
    Enum.map(files, fn file -> quote(do: @external_resource(unquote(file))) end)
  end
end
