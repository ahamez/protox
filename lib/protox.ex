defmodule Protox do

  @moduledoc"""
  Use this module to generate the Elixir modules from a set of protobuf definitions:

    ```
    defmodule Foo do
      @external_resource "./defs/foo.proto"
      @external_resource "./defs/bar.proto"
      @external_resource "./defs/baz/fiz.proto"

      use Protox, files: [
        "./defs/foo.proto",
        "./defs/bar.proto",
        "./defs/baz/fiz.proto",
      ]
    end
    ```

  Note that the files should reside in the same sub-directory.

  It's also possible to directly give a schema:

    ```
    defmodule Bar do
      use Protox, schema: \"\"\"
        syntax = "proto3";
        package fiz;

        message Baz {
        }

        message Foo {
          map<int32, Baz> b = 2;
        }
      \"\"\"
    end
    ```

  The generated modules respect the package declaration. For instance, in the above example,
  both the `Fiz.Baz` and `Fiz.Foo` modules will be generated.

  """

  defmacro __using__(args) do
    namespace = case Keyword.get(args, :namespace) do
      nil -> nil
      n   -> n |> Code.eval_quoted() |> elem(0)
    end

    files = case Keyword.delete(args, :namespace) do
      schema: <<text::binary>> ->
        filename = "#{__CALLER__.module}_#{:crypto.hash(:sha, text) |> Base.encode16()}.proto"
        filepath = Path.join([Mix.Project.build_path(), filename]) |> Path.expand()
        File.write!(filepath, text)
        [filepath]

      files: files ->
        files |> Enum.map(&Path.expand/1)
    end

    {:ok, file_descriptor_set} = Protox.Protoc.run(files)
    {enums, messages} = Protox.Parse.parse(file_descriptor_set, namespace)

    Protox.Define.define(enums, messages)
  end

end
