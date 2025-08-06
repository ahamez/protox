defmodule Protox do
  @moduledoc ~S'''
  Use this module to generate the Elixir structs corresponding to a set of protobuf definitions
  and to encode/decode instances of these structures.

  ## Elixir structs generation examples
  From a set of files:
      defmodule Dummy do
        use Protox,
          files: [
            "./defs/foo.proto",
            "./defs/bar.proto",
            "./defs/baz/fiz.proto",
          ]
      end

  From a string:
      defmodule Dummy do
        use Protox,
          schema: """
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

  ## Encoding/decoding
  For the rest of this module documentation, we suppose the following protobuf messages are defined:
      defmodule Dummy do
        use Protox,
          schema: """
            syntax = "proto3";
            package fiz;

            message Baz {
            }

            enum Enum {
              FOO = 0;
              BAR = 1;
            }

            message Foo {
              Enum a = 1;
              map<int32, Baz> b = 2;
            }
          """,
          namespace: Namespace

        use Protox,
          schema: """
          syntax = "proto3";

          message Msg {
            map<int32, string> msg_k = 8;
          }
          """

        use Protox,
          schema: """
          syntax = "proto3";

          message Sub {
            int32 a = 1;
          }
          """
      end

  See each function documentation to see how they are used to encode and decode protobuf messages.
  '''

  defmacro __using__(opts) do
    with {opts, _bindings} <- Code.eval_quoted(opts),
         {paths, opts} <- get_paths(opts),
         {files, opts} <- get_files(opts),
         {:ok, file_descriptor_set} <- Protox.Protoc.run(files, paths),
         {:ok, definition} <- Protox.Parse.parse(file_descriptor_set, opts) do
      quote do
        unquote(make_external_resources(files))
        unquote(Protox.Define.define(definition, opts))
      end
    end
  end

  @doc """
  Throwing version of `decode/2`.
  """
  @doc since: "1.6.0"
  @spec decode!(binary(), atom()) :: struct() | no_return()
  def decode!(binary, msg_module) do
    msg_module.decode!(binary)
  end

  @doc """
  Decode a binary into a protobuf message.

  ## Examples
      iex> binary = <<8, 42, 18, 7, 8, 1, 18, 3, 102, 111, 111>>
      iex> {:ok, msg} = Protox.decode(binary, ProtoxExample)
      iex> msg
      %ProtoxExample{a: 42, b: %{1 => "foo"}}

      iex> binary = <<66, 7, 8, 1, 18, 3, 102, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
      iex> {:error, reason} = Protox.decode(binary, ProtoxExample)
      iex> reason
      %Protox.DecodingError{
                    message: "Could not decode data (invalid wire type 7)",
                    binary: <<7, 8, 2, 18, 3, 98, 97, 114>>
                  }
  """
  @doc since: "1.6.0"
  @spec decode(binary(), atom()) :: {:ok, struct()} | {:error, any()}
  def decode(binary, msg_module) do
    msg_module.decode(binary)
  end

  @doc """
  Throwing version of `encode/1`.
  """
  @doc since: "1.6.0"
  @spec encode!(struct()) :: {iodata(), non_neg_integer()} | no_return()
  def encode!(msg) do
    msg.__struct__.encode!(msg)
  end

  @doc """
  Encode a protobuf message into IO data.

  ## Examples
      iex> msg = %ProtoxExample{a: 3, b: %{1 => "some string"}}
      iex> {:ok, iodata, _iodata_size} = Protox.encode(msg)
      iex> IO.iodata_to_binary(iodata)
      <<8, 3, 18, 15, 8, 1, 18, 11, 115, 111, 109, 101, 32, 115, 116, 114, 105, 110, 103>>

      iex> msg = %ProtoxExample{a: "should not be a string"}
      iex> {:error, reason} = Protox.encode(msg)
      iex> reason
      %Protox.EncodingError{field: :a, message: "Could not encode field :a (invalid field value)"}

  """
  @doc since: "1.6.0"
  @spec encode(struct()) :: {:ok, iodata(), non_neg_integer()} | {:error, any()}
  def encode(msg) do
    msg.__struct__.encode(msg)
  end

  # -- Private

  defp get_paths(opts) do
    case Keyword.pop(opts, :paths) do
      {nil, opts} -> {nil, opts}
      {paths, opts} -> {Enum.map(paths, &Path.expand/1), opts}
    end
  end

  defp get_files(opts) do
    case Keyword.pop(opts, :schema) do
      {<<text::binary>>, opts} ->
        filepath = Protox.TmpFs.tmp_file_path!(".proto")
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

  @generator_version 1
  @doc false
  def generator_version(), do: @generator_version

  @doc false
  def check_generator_version(generated_code_version) do
    if generated_code_version != generator_version() do
      raise "Mismatch detected between the protox generated code and the runtime. Please regenerate the code using the same protox version as the runtime."
    end
  end
end
