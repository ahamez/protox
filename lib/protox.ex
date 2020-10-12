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

    namespace =
      case Keyword.get(args, :namespace) do
        nil -> nil
        n -> n
      end

    path =
      case Keyword.get(args, :path) do
        nil -> nil
        p -> Path.expand(p)
      end

    files =
      case Keyword.drop(args, [:namespace, :path]) do
        schema: <<text::binary>> ->
          filename = "#{__CALLER__.module}_#{:sha |> :crypto.hash(text) |> Base.encode16()}.proto"
          filepath = [Mix.Project.build_path(), filename] |> Path.join() |> Path.expand()
          File.write!(filepath, text)
          [filepath]

        files: files ->
          Enum.map(files, &Path.expand/1)
      end

    {:ok, file_descriptor_set} = Protox.Protoc.run(files, path)
    {enums, messages} = Protox.Parse.parse(file_descriptor_set, namespace)

    quote do
      unquote(make_external_resources(files))
      unquote(Protox.Define.define(enums, messages))
    end
  end

  defmodule FileContent, do: defstruct([:name, :content])

  def generate_module_code(files, output_path, multiple_files, include_path \\ nil)
      when is_list(files) and is_binary(output_path) and is_boolean(multiple_files) do
    path =
      case include_path do
        nil -> nil
        _ -> Path.expand(include_path)
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

  def generate_file(%FileContent{name: file_name, content: content}),
    do: File.write!(file_name, content)

  defp make_external_resources(files) do
    Enum.map(files, fn file -> quote(do: @external_resource(unquote(file))) end)
  end
end
