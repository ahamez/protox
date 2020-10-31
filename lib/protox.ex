defmodule Protox do
  @moduledoc ~S'''
  Use this module to generate the Elixir modules from a set of protobuf definitions:

      defmodule Foo do
        use Protox, files: [
          "./defs/foo.proto",
          "./defs/bar.proto",
          "./defs/baz/fiz.proto",
        ]
      end

  It's also possible to directly give a schema:

      defmodule Bar do
        use Protox, schema: """
          syntax = "proto3";
          package fiz;

            message Baz {
            }

            message Foo {
              map<int32, Baz> b = 2;
            }
          """
      end

  The generated modules respect the package declaration. For instance, in the above example,
  both the `Fiz.Baz` and `Fiz.Foo` modules will be generated.

  See https://github.com/ahamez/protox/blob/master/README.md for detailed instructions.
  '''

  defmacro __using__(args) do
    {args, _} = Code.eval_quoted(args)

    {namespace, args} = get_namespace(args)
    {path, args} = get_path(args)
    {files, _args} = get_files(args)

    {:ok, file_descriptor_set} = Protox.Protoc.run(files, path)
    {enums, messages} = Protox.Parse.parse(file_descriptor_set, namespace)

    quote do
      unquote(make_external_resources(files))
      unquote(Protox.Define.define(enums, messages))
    end
  end

  defp get_namespace(args) do
    Keyword.pop(args, :namespace)
  end

  defp get_path(args) do
    case Keyword.pop(args, :path) do
      {nil, args} -> {nil, args}
      {p, args} -> {Path.expand(p), args}
    end
  end

  defp get_files(args) do
    case Keyword.pop(args, :schema) do
      {<<text::binary>>, args} ->
        filename = "#{Base.encode16(:crypto.hash(:sha, text))}.proto"
        filepath = [Mix.Project.build_path(), filename] |> Path.join() |> Path.expand()
        File.write!(filepath, text)
        {[filepath], args}

      {nil, args} ->
        {files, args} = Keyword.pop(args, :files)
        {Enum.map(files, &Path.expand/1), args}
    end
  end

  defmodule FileContent do
    @moduledoc false
    defstruct([:name, :content])
  end

  def generate_module_code(files, output_path, multiple_files, include_path_or_nil)
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

    code = quote do: unquote(Protox.Define.define(enums, messages))

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

  defp generate_file_content(code),
    do: ["#", " credo:disable-for-this-file\n", Macro.to_string(code)]

  defp make_external_resources(files) do
    Enum.map(files, fn file -> quote(do: @external_resource(unquote(file))) end)
  end
end
