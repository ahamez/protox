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
    {paths, opts} = get_paths(opts)
    {files, opts} = get_files(opts)

    {:ok, file_descriptor_set} = Protox.Protoc.run(files, paths)
    %{enums: enums, messages: messages} = Protox.Parse.parse(file_descriptor_set, namespace)

    quote do
      unquote(make_external_resources(files))
      unquote(Protox.Define.define(enums, messages, opts))
    end
  end

  @doc """
  Throwing version of `encode/1`.
  """
  @spec encode!(struct()) :: iodata() | no_return()
  def encode!(msg) do
    msg.__struct__.encode!(msg)
  end

  @doc """
  Encode a protobuf message into IO data.

  ## Example
      msg = %Fiz.Foo{a: 3, b: %{1 => %Fiz.Baz{}}}
      {:ok, iodata} = Protox.encode(msg)

  """
  @spec encode(struct()) :: {:ok, iodata()} | {:error, any()}
  def encode(msg) do
    msg.__struct__.encode(msg)
  end

  @doc """
  TODO
  """
  @spec decode!(binary(), atom()) :: struct() | no_return()
  def decode!(binary, msg_module) do
    msg_module.decode!(binary)
  end

  @doc """
  TODO
  """
  @spec decode(binary(), atom()) :: {:ok, struct()} | {:error, any()}
  def decode(binary, msg_module) do
    msg_module.decode(binary)
  end

  @doc """
  Export a proto3 message `msg` to JSON as iodata.

  See https://developers.google.com/protocol-buffers/docs/proto3#json.
  """
  @spec json_encode!(struct()) :: iodata()
  def json_encode!(msg) do
    Protox.JsonEncode.encode!(msg)
  end

  # -- Private

  defp get_namespace(opts) do
    Keyword.pop(opts, :namespace)
  end

  defp get_paths(opts) do
    case Keyword.pop(opts, :paths) do
      {nil, opts} -> get_path(opts)
      {ps, opts} -> {Enum.map(ps, &Path.expand/1), opts}
    end
  end

  defp get_path(opts) do
    case Keyword.pop(opts, :path) do
      {nil, opts} -> {nil, opts}
      {p, opts} -> {[Path.expand(p)], opts}
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

  defp make_external_resources(files) do
    Enum.map(files, fn file -> quote(do: @external_resource(unquote(file))) end)
  end
end
