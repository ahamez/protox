defmodule Protox.Decode do
  @moduledoc false
  # Helpers decoding functions that will be used by the generated code.

  import Bitwise

  use Protox.{
    Float,
    WireTypes
  }

  alias Protox.{
    Varint,
    Zigzag
  }

  @compile {:inline,
            parse_bool: 1,
            parse_sint32: 1,
            parse_sint64: 1,
            parse_uint32: 1,
            parse_uint64: 1,
            parse_enum: 2,
            parse_int32: 1,
            parse_int64: 1,
            parse_double: 1,
            parse_float: 1,
            parse_fixed32: 1,
            parse_sfixed32: 1,
            parse_fixed64: 1,
            parse_sfixed64: 1}

  # Get the key's tag and wire type.
  @spec parse_key(binary()) :: {non_neg_integer(), non_neg_integer(), binary()}
  def parse_key(bytes) do
    {key, rest} = Varint.decode(bytes)
    wire_type = key &&& 0b0000_0111

    if wire_type in [@wire_32bits, @wire_64bits, @wire_delimited, @wire_varint] do
      {key >>> 3, wire_type, rest}
    else
      raise Protox.DecodingError.new(bytes, "invalid wire type #{wire_type}")
    end
  end

  def parse_unknown(tag, @wire_varint, bytes) do
    {unknown_bytes, rest} = get_unknown_varint_bytes(<<>>, bytes)
    {{tag, @wire_varint, unknown_bytes}, rest}
  end

  def parse_unknown(tag, @wire_64bits, <<unknown_bytes::64, rest::binary>>) do
    {{tag, @wire_64bits, <<unknown_bytes::64>>}, rest}
  end

  def parse_unknown(tag, @wire_delimited, bytes) do
    {len, new_bytes} = Varint.decode(bytes)

    try do
      <<unknown_bytes::binary-size(len), rest::binary>> = new_bytes
      {{tag, @wire_delimited, unknown_bytes}, rest}
    rescue
      _ ->
        reraise Protox.DecodingError.new(bytes, "invalid bytes for unknown delimited"),
                __STACKTRACE__
    end
  end

  def parse_unknown(tag, @wire_32bits, <<unknown_bytes::32, rest::binary>>) do
    {{tag, @wire_32bits, <<unknown_bytes::32>>}, rest}
  end

  def parse_unknown(_tag, _wire_type, bytes) do
    raise Protox.DecodingError.new(bytes, "can't parse unknown bytes")
  end

  defp get_unknown_varint_bytes(acc, <<0::1, b::7, rest::binary>>) do
    {<<acc::binary, 0::1, b::7>>, rest}
  end

  defp get_unknown_varint_bytes(acc, <<1::1, b::7, rest::binary>>) do
    get_unknown_varint_bytes(<<acc::binary, 1::1, b::7>>, rest)
  end

  defp get_unknown_varint_bytes(_acc, bytes) do
    raise Protox.DecodingError.new(bytes, "can't parse unknown varint bytes")
  end

  def parse_double(<<@positive_infinity_64, rest::binary>>), do: {:infinity, rest}
  def parse_double(<<@negative_infinity_64, rest::binary>>), do: {:"-infinity", rest}
  def parse_double(<<_::48, 0b1111::4, _::4, _::1, 0b1111111::7, rest::binary>>), do: {:nan, rest}
  def parse_double(<<value::float-little-64, rest::binary>>), do: {value, rest}
  def parse_double(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid double"))

  def parse_float(<<@positive_infinity_32, rest::binary>>), do: {:infinity, rest}
  def parse_float(<<@negative_infinity_32, rest::binary>>), do: {:"-infinity", rest}
  def parse_float(<<_::16, 1::1, _::7, _::1, 0b1111111::7, rest::binary>>), do: {:nan, rest}
  def parse_float(<<value::float-little-32, rest::binary>>), do: {value, rest}
  def parse_float(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid float"))

  def parse_sfixed64(<<value::signed-little-64, rest::binary>>), do: {value, rest}
  def parse_sfixed64(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid sfixed64"))

  def parse_fixed64(<<value::unsigned-little-64, rest::binary>>), do: {value, rest}
  def parse_fixed64(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid fixed64"))

  def parse_sfixed32(<<value::signed-little-32, rest::binary>>), do: {value, rest}
  def parse_sfixed32(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid sfixed32"))

  def parse_fixed32(<<value::unsigned-little-32, rest::binary>>), do: {value, rest}
  def parse_fixed32(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid fixed32"))

  def parse_bool(bytes) do
    {value, rest} = Varint.decode(bytes)
    {value != 0, rest}
  end

  def parse_sint32(bytes) do
    {value, rest} = Varint.decode(bytes)
    <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
    {Zigzag.decode(res), rest}
  end

  def parse_sint64(bytes) do
    {value, rest} = Varint.decode(bytes)
    <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
    {Zigzag.decode(res), rest}
  end

  def parse_uint32(bytes) do
    {value, rest} = Varint.decode(bytes)

    <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
    {res, rest}
  end

  def parse_uint64(bytes) do
    {value, rest} = Varint.decode(bytes)
    <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
    {res, rest}
  end

  def parse_enum(bytes, mod) do
    {value, rest} = Varint.decode(bytes)
    <<res::signed-native-32>> = <<value::signed-native-32>>
    {mod.decode(res), rest}
  end

  def parse_int32(bytes) do
    {value, rest} = Varint.decode(bytes)
    <<res::signed-native-32>> = <<value::signed-native-32>>
    {res, rest}
  end

  def parse_int64(bytes) do
    {value, rest} = Varint.decode(bytes)
    <<res::signed-native-64>> = <<value::signed-native-64>>
    {res, rest}
  end

  def validate_string!(bytes) do
    case Protox.String.validate(bytes) do
      :ok ->
        bytes

      {:error, :invalid_utf8} ->
        raise Protox.DecodingError.new(bytes, "string is not valid UTF-8")

      {:error, :too_large} ->
        raise Protox.DecodingError.new(bytes, "string is too large")
    end
  end

  def parse_repeated_bool(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_bool(acc, bytes) do
    {value, rest} = Protox.Varint.decode(bytes)
    parse_repeated_bool([value != 0 | acc], rest)
  end

  def parse_repeated_enum(acc, <<>>, _mod), do: Enum.reverse(acc)

  def parse_repeated_enum(acc, bytes, mod) do
    {value, rest} = parse_enum(bytes, mod)
    parse_repeated_enum([value | acc], rest, mod)
  end

  def parse_repeated_int32(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_int32(acc, bytes) do
    {value, rest} = parse_int32(bytes)
    parse_repeated_int32([value | acc], rest)
  end

  def parse_repeated_uint32(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_uint32(acc, bytes) do
    {value, rest} = parse_uint32(bytes)
    parse_repeated_uint32([value | acc], rest)
  end

  def parse_repeated_sint32(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_sint32(acc, bytes) do
    {value, rest} = parse_sint32(bytes)
    parse_repeated_sint32([value | acc], rest)
  end

  def parse_repeated_int64(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_int64(acc, bytes) do
    {value, rest} = parse_int64(bytes)
    parse_repeated_int64([value | acc], rest)
  end

  def parse_repeated_uint64(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_uint64(acc, bytes) do
    {value, rest} = parse_uint64(bytes)
    parse_repeated_uint64([value | acc], rest)
  end

  def parse_repeated_sint64(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_sint64(acc, bytes) do
    {value, rest} = parse_sint64(bytes)
    parse_repeated_sint64([value | acc], rest)
  end

  def parse_repeated_fixed32(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_fixed32(acc, bytes) do
    {value, rest} = parse_fixed32(bytes)
    parse_repeated_fixed32([value | acc], rest)
  end

  def parse_repeated_fixed64(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_fixed64(acc, bytes) do
    {value, rest} = parse_fixed64(bytes)
    parse_repeated_fixed64([value | acc], rest)
  end

  def parse_repeated_sfixed32(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_sfixed32(acc, bytes) do
    {value, rest} = parse_sfixed32(bytes)
    parse_repeated_sfixed32([value | acc], rest)
  end

  def parse_repeated_sfixed64(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_sfixed64(acc, bytes) do
    {value, rest} = parse_sfixed64(bytes)
    parse_repeated_sfixed64([value | acc], rest)
  end

  def parse_repeated_float(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_float(acc, bytes) do
    {value, rest} = parse_float(bytes)
    parse_repeated_float([value | acc], rest)
  end

  def parse_repeated_double(acc, <<>>), do: Enum.reverse(acc)

  def parse_repeated_double(acc, bytes) do
    {value, rest} = parse_double(bytes)
    parse_repeated_double([value | acc], rest)
  end

  def parse_delimited(bytes, len) do
    try do
      <<value::binary-size(len), rest::binary>> = bytes

      {value, rest}
    rescue
      _ ->
        reraise Protox.DecodingError.new(bytes, "invalid bytes for delimited field"),
                __STACKTRACE__
    end
  end
end
