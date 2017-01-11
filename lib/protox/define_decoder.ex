defmodule Protox.DefineDecoder do

  @moduledoc false
  # Internal. Generates the decoder of a message.

  def define(fields, required_fields) do
    make_decode(fields, required_fields)
  end

  import Protox.Guards


  # -- Private


  defp make_decode(fields, _required_fields) do
    [
      quote do
        @spec decode2!(binary) :: struct | no_return
        def decode2!(bytes) do
          # TODO. Handle required fields.

          __MODULE__.__struct__
          |> struct()
          |> parse(bytes)
        end


        @spec decode2(binary) :: {:ok, struct} | {:error, any}
        def decode2(bytes) do
          try do
            {:ok, decode2!(bytes)}
          rescue
            e -> {:error, e}
          end
        end


        defp parse(msg, <<>>), do: msg
      end
    ]
    ++
    Enum.map(fields, &make_parse_bytes_fun/1)
    ++
    [
      quote do
        defp parse(msg, bytes) do
          {tag, wire_type, rest} = Protox.Decode.parse_key(bytes)
          Protox.Decode.parse_unknown(msg, tag, wire_type, rest)
        end
      end
    ]
  end


  defp make_parse_bytes_fun({tag, _, name, {:default, _}, type})
  when is_primitive_varint(type) or elem(type, 0) == :enum
  do
    key_bytes = make_key_bytes(tag, type)
    decode_value = make_decode_varint_value_ast(type)

    quote do
      defp parse(msg, <<unquote(key_bytes), bytes::binary>>) do
        {value, rest} = Varint.LEB128.decode(bytes)

        msg
        |> struct([{unquote(name), unquote(decode_value)}])
        |> parse(rest)
      end
    end
  end
  defp make_parse_bytes_fun({tag, _, name, {:default, _}, type})
  when is_primitive_fixed(type)
  do
    key_bytes = make_key_bytes(tag, type)
    fixed_value = make_decode_fixed_value_ast(type)

    quote do
      defp parse(msg, <<unquote(key_bytes), bytes::binary>>) do
        unquote(fixed_value)

        msg
        |> struct([{unquote(name), value}])
        |> parse(rest)
      end
    end
  end
  defp make_parse_bytes_fun({tag, _, name, {:default, _}, type})
  when is_delimited(type)
  do
    key_bytes = make_key_bytes(tag, type)

    quote do
      defp parse(msg, <<unquote(key_bytes), bytes::binary>>) do
        {len, new_bytes} = Varint.LEB128.decode(bytes)
        <<delimited::binary-size(len), rest::binary>> = new_bytes

        # TODO parse message

        msg
        |> struct([{unquote(name), delimited}])
        |> parse(rest)
      end
    end
  end
  # defp make_parse_bytes_fun({tag, :repeated, name, :packed, type}) do
  # end
  # defp make_parse_bytes_fun({tag, :repeated, name, :unpacked, type}) do
  # end

  # TMP
  defp make_parse_bytes_fun(_) do
    quote do
    end
  end


  defp make_key_bytes(tag, type) do
    [Protox.Encode.make_key_bytes(tag, type)]
    |> :binary.list_to_bin()
  end

  defp make_decode_varint_value_ast(:bool) do
    quote do: value == 1
  end
  defp make_decode_varint_value_ast(:sint32) do
    quote do: Varint.Zigzag.decode(value)
  end
  defp make_decode_varint_value_ast(:sint64) do
    quote do: Varint.Zigzag.decode(value)
  end
  defp make_decode_varint_value_ast(:uint32) do
    quote do: value
  end
  defp make_decode_varint_value_ast(:uint64) do
    quote do: value
  end
  defp make_decode_varint_value_ast(:int32) do
    quote do
      <<res::signed-32>> = <<value::32>>
      res
    end
  end
  defp make_decode_varint_value_ast(:int64) do
    quote do
      <<res::signed-64>> = <<value::64>>
      res
    end
  end
  defp make_decode_varint_value_ast({:enum, mod}) do
    quote do
      <<res::signed-64>> = <<value::64>>
      unquote(mod).decode(res)
    end
  end

  defp make_decode_fixed_value_ast(:float) do
    quote do
      <<value::float-little-32, rest::binary>> = bytes
    end
  end
  defp make_decode_fixed_value_ast(:fixed32) do
    quote do
      <<value::little-32, rest::binary>> = bytes
    end
  end
  defp make_decode_fixed_value_ast(:sfixed32) do
    quote do
      <<value::signed-little-32, rest::binary>> = bytes
    end
  end
  defp make_decode_fixed_value_ast(:double) do
    quote do
      <<value::float-little-64, rest::binary>> = bytes
    end
  end
  defp make_decode_fixed_value_ast(:fixed64) do
    quote do
      <<value::little-64, rest::binary>> = bytes
    end
  end
  defp make_decode_fixed_value_ast(:sfixed64) do
    quote do
      <<value::signed-little-64, rest::binary>> = bytes
    end
  end

end
