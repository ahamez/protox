defmodule Protox do
  @moduledoc ~S'''
  Use this module to generate the Elixir structs corresponding to a set of protobuf definitions
  and to encode/decode instances of these structures.

  ## Elixit structs generation examples
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
    {opts, _} = Code.eval_quoted(opts)

    {paths, opts} = get_paths(opts)
    {files, opts} = get_files(opts)

    {:ok, file_descriptor_set} = Protox.Protoc.run(files, paths)

    %{enums: enums, messages: messages} = Protox.Parse.parse(file_descriptor_set, opts)

    quote do
      unquote(make_external_resources(files))
      unquote(Protox.Define.define(enums, messages, opts))
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
      iex> binary = <<66, 7, 8, 1, 18, 3, 102, 111, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
      iex> {:ok, msg} = Protox.decode(binary, Msg)
      iex> msg
      %Msg{msg_k: %{1 => "foo", 2 => "bar"}}

      iex> binary = <<66, 7, 8, 1, 18, 3, 102, 111, 66, 7, 8, 2, 18, 3, 98, 97, 114>>
      iex> {:error, reason} = Protox.decode(binary, Msg)
      iex> reason
      %Protox.IllegalTagError{message: "Field with illegal tag 0"}
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
  @spec encode!(struct()) :: iodata() | no_return()
  def encode!(msg) do
    msg.__struct__.encode!(msg)
  end

  @doc """
  Encode a protobuf message into IO data.

  ## Examples
      iex> msg = %Namespace.Fiz.Foo{a: 3, b: %{1 => %Namespace.Fiz.Baz{}}}
      iex> {:ok, iodata} = Protox.encode(msg)
      iex> :binary.list_to_bin(iodata)
      <<8, 3, 18, 4, 8, 1, 18, 0>>

      iex> msg = %Namespace.Fiz.Foo{a: "should not be a string"}
      iex> {:error, reason} = Protox.encode(msg)
      iex> reason
      %Protox.EncodingError{field: :a, message: "Could not encode field :a (invalid field value)"}

  """
  @doc since: "1.6.0"
  @spec encode(struct()) :: {:ok, iodata()} | {:error, any()}
  def encode(msg) do
    msg.__struct__.encode(msg)
  end

  @doc """
  ## Errors
  This function returns a tuple `{:error, reason}` if:
  - `input` could not be decoded to JSON; `reason` is a `Protox.JsonDecodingError` error
  """
  @doc since: "2.0.0"
  @spec json_decode(iodata(), atom()) :: {:ok, struct()} | {:error, any()}
  def json_decode(input, message_module) do
    message_module.json_decode(input)
  end

  @doc """
  Throwing version of `json_decode/2`.
  """
  @doc since: "2.0.0"
  @spec json_decode!(iodata(), atom()) :: struct() | no_return()
  def json_decode!(input, message_module) do
    message_module.json_decode!(input)
  end

  @doc """
  Export a proto3 message to JSON as IO data.

  ## Errors
  This function returns a tuple `{:error, reason}` if:
  - `msg` could not be encoded to JSON; `reason` is a `Protox.JsonEncodingError` error

  ## Examples
      iex> msg = %Namespace.Fiz.Foo{a: :BAR}
      iex> {:ok, iodata} = Protox.json_encode(msg)
      iex> iodata
      ["{", [[34, [[] | "a"], 34], ":", [34, [[] | "BAR"], 34]], "}"]

      iex> msg = %Sub{a: 42}
      iex> {:ok, iodata} = Protox.json_encode(msg)
      iex> iodata
      ["{", [[34, [[] | "a"], 34], ":", "42"], "}"]

      iex> msg = %Msg{msg_k: %{1 => "foo", 2 => "bar"}}
      iex> {:ok, iodata} = msg |> Protox.json_encode()
      iex> :binary.list_to_bin(iodata)
      "{\\"msgK\\":{\\"2\\":\\"bar\\",\\"1\\":\\"foo\\"}}"
  """
  @doc since: "2.0.0"
  @spec json_encode(struct()) :: {:ok, iodata()} | {:error, any()}
  def json_encode(msg) do
    msg.__struct__.json_encode(msg)
  end

  @doc """
  Throwing version of `json_encode/1`.
  """
  @doc since: "2.0.0"
  @spec json_encode!(struct()) :: iodata() | no_return()
  def json_encode!(msg) do
    msg.__struct__.json_encode!(msg)
  end

  # -- Private

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
        filepath = [System.tmp_dir!(), filename] |> Path.join() |> Path.expand()
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
