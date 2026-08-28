defmodule Protox.Decode do
  @moduledoc false
  # Helpers decoding functions that will be used by the generated code.
  use Protox.{
    Float,
    WireTypes
  }

  import Bitwise

  alias Protox.{
    Varint,
    Zigzag
  }

  alias Protox.Varint.DecodeClauses

  # Protobuf keys reserve the low 3 bits for the wire type, leaving 29 bits for the field number.
  @max_field_number (1 <<< 29) - 1

  @compile {:inline,
            parse_delimited: 2,
            truncate_unsigned32: 1,
            truncate_unsigned64: 1,
            truncate_signed32: 1,
            truncate_signed64: 1,
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
            parse_sfixed64: 1,
            parse_repeated_bool: 2,
            parse_repeated_enum: 3,
            parse_repeated_int32: 2,
            parse_repeated_uint32: 2,
            parse_repeated_sint32: 2,
            parse_repeated_int64: 2,
            parse_repeated_uint64: 2,
            parse_repeated_sint64: 2,
            parse_repeated_fixed32: 2,
            parse_repeated_fixed64: 2,
            parse_repeated_sfixed32: 2,
            parse_repeated_sfixed64: 2,
            parse_repeated_float: 2,
            parse_repeated_double: 2}

  # Get the key's tag and wire type.
  @spec parse_key(binary()) :: {non_neg_integer(), non_neg_integer(), binary()}
  def parse_key(bytes) do
    {key, rest} = Varint.decode(bytes)
    key_size = byte_size(bytes) - byte_size(rest)
    field_number = key >>> 3

    # Reject overlong key varints: an LEB128 encoding is canonical iff its last
    # byte (the highest 7-bit group) is non-zero, or the varint is a single byte.
    if key_size > 1 and key >>> (7 * (key_size - 1)) == 0 do
      raise Protox.DecodingError.new(bytes, "invalid key varint")
    end

    if field_number > @max_field_number do
      raise Protox.DecodingError.new(bytes, "field number out of range")
    end

    case _wire_type = key &&& 0b0000_0111 do
      @wire_32bits -> {field_number, @wire_32bits, rest}
      @wire_64bits -> {field_number, @wire_64bits, rest}
      @wire_delimited -> {field_number, @wire_delimited, rest}
      @wire_varint -> {field_number, @wire_varint, rest}
    end
  end

  @spec parse_unknown(non_neg_integer(), Protox.Types.tag(), binary()) ::
          {{non_neg_integer(), Protox.Types.tag(), binary()}, binary()}
  def parse_unknown(tag, @wire_varint, bytes) do
    size = unknown_varint_size(bytes, 0)
    <<unknown_bytes::binary-size(^size), rest::binary>> = bytes

    # Copied so the stored unknown bytes don't keep the whole payload alive.
    {{tag, @wire_varint, :binary.copy(unknown_bytes)}, rest}
  end

  def parse_unknown(tag, @wire_64bits, <<unknown_bytes::64, rest::binary>>) do
    {{tag, @wire_64bits, <<unknown_bytes::64>>}, rest}
  end

  def parse_unknown(tag, @wire_delimited, bytes) do
    {len, new_bytes} = Varint.decode(bytes)

    case new_bytes do
      <<unknown_bytes::binary-size(^len), rest::binary>> ->
        {{tag, @wire_delimited, unknown_bytes}, rest}

      _invalid_bytes ->
        raise Protox.DecodingError.new(bytes, "invalid bytes for unknown delimited")
    end
  end

  def parse_unknown(tag, @wire_32bits, <<unknown_bytes::32, rest::binary>>) do
    {{tag, @wire_32bits, <<unknown_bytes::32>>}, rest}
  end

  def parse_unknown(_tag, _wire_type, bytes) do
    raise Protox.DecodingError.new(bytes, "can't parse unknown bytes")
  end

  defp unknown_varint_size(<<0::1, _byte::7, _rest::binary>>, acc), do: acc + 1

  defp unknown_varint_size(<<1::1, _byte::7, rest::binary>>, acc) do
    unknown_varint_size(rest, acc + 1)
  end

  defp unknown_varint_size(bytes, _acc) do
    raise Protox.DecodingError.new(bytes, "can't parse unknown varint bytes")
  end

  @spec parse_double(binary()) :: {float() | :infinity | :"-infinity" | :nan, binary()}
  def parse_double(<<@positive_infinity_64, rest::binary>>), do: {:infinity, rest}
  def parse_double(<<@negative_infinity_64, rest::binary>>), do: {:"-infinity", rest}

  def parse_double(<<_fraction_low::48, 0b1111::4, _fraction_high::4, _sign::1, 0b1111111::7, rest::binary>>),
    do: {:nan, rest}

  def parse_double(<<value::float-little-64, rest::binary>>), do: {value, rest}
  def parse_double(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid double"))

  @spec parse_float(binary()) :: {float() | :infinity | :"-infinity" | :nan, binary()}
  def parse_float(<<@positive_infinity_32, rest::binary>>), do: {:infinity, rest}
  def parse_float(<<@negative_infinity_32, rest::binary>>), do: {:"-infinity", rest}

  def parse_float(<<_fraction_low::16, 1::1, _fraction_high::7, _sign::1, 0b1111111::7, rest::binary>>),
    do: {:nan, rest}

  def parse_float(<<value::float-little-32, rest::binary>>), do: {value, rest}
  def parse_float(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid float"))

  @spec parse_sfixed64(binary()) :: {integer(), binary()}
  def parse_sfixed64(<<value::signed-little-64, rest::binary>>), do: {value, rest}
  def parse_sfixed64(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid sfixed64"))

  @spec parse_fixed64(binary()) :: {non_neg_integer(), binary()}
  def parse_fixed64(<<value::unsigned-little-64, rest::binary>>), do: {value, rest}
  def parse_fixed64(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid fixed64"))

  @spec parse_sfixed32(binary()) :: {integer(), binary()}
  def parse_sfixed32(<<value::signed-little-32, rest::binary>>), do: {value, rest}
  def parse_sfixed32(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid sfixed32"))

  @spec parse_fixed32(binary()) :: {non_neg_integer(), binary()}
  def parse_fixed32(<<value::unsigned-little-32, rest::binary>>), do: {value, rest}
  def parse_fixed32(bytes), do: raise(Protox.DecodingError.new(bytes, "invalid fixed32"))

  @spec parse_bool(binary()) :: {boolean(), binary()}
  def parse_bool(bytes) do
    {value, rest} = Varint.decode(bytes)
    {value != 0, rest}
  end

  @spec parse_sint32(binary()) :: {integer(), binary()}
  def parse_sint32(bytes) do
    {value, rest} = Varint.decode(bytes)
    {Zigzag.decode(truncate_unsigned32(value)), rest}
  end

  @spec parse_sint64(binary()) :: {integer(), binary()}
  def parse_sint64(bytes) do
    {value, rest} = Varint.decode(bytes)
    {Zigzag.decode(truncate_unsigned64(value)), rest}
  end

  @spec parse_uint32(binary()) :: {non_neg_integer(), binary()}
  def parse_uint32(bytes) do
    {value, rest} = Varint.decode(bytes)
    {truncate_unsigned32(value), rest}
  end

  @spec parse_uint64(binary()) :: {non_neg_integer(), binary()}
  def parse_uint64(bytes) do
    {value, rest} = Varint.decode(bytes)
    {truncate_unsigned64(value), rest}
  end

  @spec parse_enum(binary(), module()) :: {atom() | integer(), binary()}
  def parse_enum(bytes, mod) do
    {value, rest} = Varint.decode(bytes)
    {mod.decode(truncate_signed32(value)), rest}
  end

  @spec parse_int32(binary()) :: {integer(), binary()}
  def parse_int32(bytes) do
    {value, rest} = Varint.decode(bytes)
    {truncate_signed32(value), rest}
  end

  @spec parse_int64(binary()) :: {integer(), binary()}
  def parse_int64(bytes) do
    {value, rest} = Varint.decode(bytes)
    {truncate_signed64(value), rest}
  end

  defp truncate_unsigned32(value), do: value &&& 0xFFFF_FFFF
  defp truncate_unsigned64(value), do: value &&& 0xFFFF_FFFF_FFFF_FFFF

  defp truncate_signed32(value) do
    case value &&& 0xFFFF_FFFF do
      truncated when truncated >= 0x8000_0000 -> truncated - 0x1_0000_0000
      truncated -> truncated
    end
  end

  defp truncate_signed64(value) do
    case value &&& 0xFFFF_FFFF_FFFF_FFFF do
      truncated when truncated >= 0x8000_0000_0000_0000 -> truncated - 0x1_0000_0000_0000_0000
      truncated -> truncated
    end
  end

  @spec validate_string!(binary()) :: binary() | no_return()
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

  # The parse_repeated_* functions prepend the decoded elements onto `acc`, so the
  # result is in reverse wire order. Callers seed `acc` with the field's current
  # (also reversed) list and rely on the single reverse in the generated
  # finish-decode step to restore wire order — reversing here as well would cost
  # two extra list copies per packed run.
  #
  # The varint loops below get one clause per encoded length (1 to 10 bytes).
  # Matching the varint in the loop's own clause instead of calling the
  # cross-module Varint.decode/1 avoids a {value, rest} tuple and a sub-binary
  # per element. Covering all 10 lengths matters: a valid varint falling through
  # to the closing clause would convert the match context back to a sub-binary
  # on every element. Only over-long (non-canonical, > 10 bytes) and invalid
  # trailing bytes take the closing clause, which still uses Varint.decode/1.
  varint_rest = Macro.var(:rest, __MODULE__)
  varint_fast_clauses = DecodeClauses.build(1..10, varint_rest)

  @spec parse_repeated_bool([boolean()], binary()) :: [boolean()]
  def parse_repeated_bool(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_bool(acc, unquote(pattern)) do
      parse_repeated_bool([unquote(value) != 0 | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_bool(acc, bytes) do
    {value, rest} = Protox.Varint.decode(bytes)
    parse_repeated_bool([value != 0 | acc], rest)
  end

  @spec parse_repeated_enum([atom() | integer()], binary(), module()) :: [atom() | integer()]
  def parse_repeated_enum(acc, <<>>, _mod), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_enum(acc, unquote(pattern), mod) do
      parse_repeated_enum([mod.decode(truncate_signed32(unquote(value))) | acc], unquote(varint_rest), mod)
    end
  end

  def parse_repeated_enum(acc, bytes, mod) do
    {value, rest} = parse_enum(bytes, mod)
    parse_repeated_enum([value | acc], rest, mod)
  end

  @spec parse_repeated_int32([integer()], binary()) :: [integer()]
  def parse_repeated_int32(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_int32(acc, unquote(pattern)) do
      parse_repeated_int32([truncate_signed32(unquote(value)) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_int32(acc, bytes) do
    {value, rest} = parse_int32(bytes)
    parse_repeated_int32([value | acc], rest)
  end

  @spec parse_repeated_uint32([non_neg_integer()], binary()) :: [non_neg_integer()]
  def parse_repeated_uint32(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_uint32(acc, unquote(pattern)) do
      parse_repeated_uint32([truncate_unsigned32(unquote(value)) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_uint32(acc, bytes) do
    {value, rest} = parse_uint32(bytes)
    parse_repeated_uint32([value | acc], rest)
  end

  @spec parse_repeated_sint32([integer()], binary()) :: [integer()]
  def parse_repeated_sint32(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_sint32(acc, unquote(pattern)) do
      parse_repeated_sint32([Zigzag.decode(truncate_unsigned32(unquote(value))) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_sint32(acc, bytes) do
    {value, rest} = parse_sint32(bytes)
    parse_repeated_sint32([value | acc], rest)
  end

  @spec parse_repeated_int64([integer()], binary()) :: [integer()]
  def parse_repeated_int64(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_int64(acc, unquote(pattern)) do
      parse_repeated_int64([truncate_signed64(unquote(value)) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_int64(acc, bytes) do
    {value, rest} = parse_int64(bytes)
    parse_repeated_int64([value | acc], rest)
  end

  @spec parse_repeated_uint64([non_neg_integer()], binary()) :: [non_neg_integer()]
  def parse_repeated_uint64(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_uint64(acc, unquote(pattern)) do
      parse_repeated_uint64([truncate_unsigned64(unquote(value)) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_uint64(acc, bytes) do
    {value, rest} = parse_uint64(bytes)
    parse_repeated_uint64([value | acc], rest)
  end

  @spec parse_repeated_sint64([integer()], binary()) :: [integer()]
  def parse_repeated_sint64(acc, <<>>), do: acc

  for {pattern, value} <- varint_fast_clauses do
    def parse_repeated_sint64(acc, unquote(pattern)) do
      parse_repeated_sint64([Zigzag.decode(truncate_unsigned64(unquote(value))) | acc], unquote(varint_rest))
    end
  end

  def parse_repeated_sint64(acc, bytes) do
    {value, rest} = parse_sint64(bytes)
    parse_repeated_sint64([value | acc], rest)
  end

  @spec parse_repeated_fixed32([non_neg_integer()], binary()) :: [non_neg_integer()]
  def parse_repeated_fixed32(acc, <<>>), do: acc

  def parse_repeated_fixed32(
        acc,
        <<a::unsigned-little-32, b::unsigned-little-32, c::unsigned-little-32, d::unsigned-little-32, rest::binary>>
      ) do
    parse_repeated_fixed32([d, c, b, a | acc], rest)
  end

  def parse_repeated_fixed32(acc, bytes) do
    {value, rest} = parse_fixed32(bytes)
    parse_repeated_fixed32([value | acc], rest)
  end

  @spec parse_repeated_fixed64([non_neg_integer()], binary()) :: [non_neg_integer()]
  def parse_repeated_fixed64(acc, <<>>), do: acc

  def parse_repeated_fixed64(
        acc,
        <<a::unsigned-little-64, b::unsigned-little-64, c::unsigned-little-64, d::unsigned-little-64, rest::binary>>
      ) do
    parse_repeated_fixed64([d, c, b, a | acc], rest)
  end

  def parse_repeated_fixed64(acc, bytes) do
    {value, rest} = parse_fixed64(bytes)
    parse_repeated_fixed64([value | acc], rest)
  end

  @spec parse_repeated_sfixed32([integer()], binary()) :: [integer()]
  def parse_repeated_sfixed32(acc, <<>>), do: acc

  def parse_repeated_sfixed32(
        acc,
        <<a::signed-little-32, b::signed-little-32, c::signed-little-32, d::signed-little-32, rest::binary>>
      ) do
    parse_repeated_sfixed32([d, c, b, a | acc], rest)
  end

  def parse_repeated_sfixed32(acc, bytes) do
    {value, rest} = parse_sfixed32(bytes)
    parse_repeated_sfixed32([value | acc], rest)
  end

  @spec parse_repeated_sfixed64([integer()], binary()) :: [integer()]
  def parse_repeated_sfixed64(acc, <<>>), do: acc

  def parse_repeated_sfixed64(
        acc,
        <<a::signed-little-64, b::signed-little-64, c::signed-little-64, d::signed-little-64, rest::binary>>
      ) do
    parse_repeated_sfixed64([d, c, b, a | acc], rest)
  end

  def parse_repeated_sfixed64(acc, bytes) do
    {value, rest} = parse_sfixed64(bytes)
    parse_repeated_sfixed64([value | acc], rest)
  end

  @spec parse_repeated_float([float() | :infinity | :"-infinity" | :nan], binary()) :: [
          float() | :infinity | :"-infinity" | :nan
        ]
  def parse_repeated_float(acc, <<>>), do: acc

  # A float segment never matches NaN or infinity payloads: those fall through
  # to the single-element clause below, which handles them.
  def parse_repeated_float(
        acc,
        <<a::float-little-32, b::float-little-32, c::float-little-32, d::float-little-32, rest::binary>>
      ) do
    parse_repeated_float([d, c, b, a | acc], rest)
  end

  def parse_repeated_float(acc, bytes) do
    {value, rest} = parse_float(bytes)
    parse_repeated_float([value | acc], rest)
  end

  @spec parse_repeated_double([float() | :infinity | :"-infinity" | :nan], binary()) :: [
          float() | :infinity | :"-infinity" | :nan
        ]
  def parse_repeated_double(acc, <<>>), do: acc

  # A float segment never matches NaN or infinity payloads: those fall through
  # to the single-element clause below, which handles them.
  def parse_repeated_double(
        acc,
        <<a::float-little-64, b::float-little-64, c::float-little-64, d::float-little-64, rest::binary>>
      ) do
    parse_repeated_double([d, c, b, a | acc], rest)
  end

  def parse_repeated_double(acc, bytes) do
    {value, rest} = parse_double(bytes)
    parse_repeated_double([value | acc], rest)
  end

  @spec parse_delimited(binary(), non_neg_integer()) :: {binary(), binary()} | no_return()
  def parse_delimited(bytes, len) do
    case bytes do
      <<value::binary-size(^len), rest::binary>> ->
        {value, rest}

      _invalid_bytes ->
        raise Protox.DecodingError.new(bytes, "invalid bytes for delimited field")
    end
  end
end
