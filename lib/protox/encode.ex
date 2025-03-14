defmodule Protox.Encode do
  @moduledoc false

  use Protox.{
    Float,
    WireTypes
  }

  import Bitwise
  import Protox.Guards

  alias Protox.{
    Varint,
    Zigzag
  }

  @doc false
  @spec make_key_bytes(Protox.Types.tag(), Protox.Types.type()) :: {binary(), non_neg_integer()}
  def make_key_bytes(tag, ty) do
    Varint.encode(make_key(tag, ty))
  end

  @doc false
  @spec make_key(Protox.Types.tag(), Protox.Types.type()) :: non_neg_integer()
  def make_key(tag, ty) when is_primitive_varint(ty), do: tag <<< 3 ||| @wire_varint
  def make_key(tag, {:enum, _}), do: tag <<< 3 ||| @wire_varint
  def make_key(tag, ty) when is_primitive_fixed64(ty), do: tag <<< 3 ||| @wire_64bits
  def make_key(tag, ty) when is_delimited(ty), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, {:message, _}), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, :packed), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, :map_entry), do: tag <<< 3 ||| @wire_delimited
  def make_key(tag, ty) when is_primitive_fixed32(ty), do: tag <<< 3 ||| @wire_32bits

  @doc false
  @spec encode_varint_signed(integer()) :: {binary(), non_neg_integer()}
  def encode_varint_signed(value) do
    value |> Zigzag.encode() |> Varint.encode()
  end

  @doc false
  @spec encode_varint_64(integer()) :: {binary(), non_neg_integer()}
  def encode_varint_64(value) do
    <<res::unsigned-native-64>> = <<value::signed-native-64>>
    Varint.encode(res)
  end

  @doc false
  @spec encode_varint_32(integer()) :: {binary(), non_neg_integer()}
  def encode_varint_32(value) when value < 0 do
    encode_varint_64(value)
  end

  @doc false
  def encode_varint_32(value) do
    <<res::unsigned-native-32>> = <<value::signed-native-32>>

    Varint.encode(res)
  end

  @doc false
  @spec encode_bool(boolean()) :: {binary(), non_neg_integer()}
  def encode_bool(false), do: {<<0>>, 1}
  def encode_bool(true), do: {<<1>>, 1}

  @doc false
  @spec encode_int32(integer()) :: {binary(), non_neg_integer()}
  def encode_int32(value), do: encode_varint_32(value)

  @doc false
  @spec encode_int64(integer()) :: {binary(), non_neg_integer()}
  def encode_int64(value), do: encode_varint_64(value)

  @doc false
  @spec encode_sint32(integer()) :: {binary(), non_neg_integer()}
  def encode_sint32(value), do: encode_varint_signed(value)

  @doc false
  @spec encode_sint64(integer()) :: {binary(), non_neg_integer()}
  def encode_sint64(value), do: encode_varint_signed(value)

  @doc false
  @spec encode_uint32(non_neg_integer()) :: {binary(), non_neg_integer()}
  def encode_uint32(value), do: encode_varint_32(value)

  @doc false
  @spec encode_uint64(non_neg_integer()) :: {binary(), non_neg_integer()}
  def encode_uint64(value), do: encode_varint_64(value)

  @doc false
  @spec encode_fixed64(integer()) :: {binary(), non_neg_integer()}
  def encode_fixed64(value), do: {<<value::little-64>>, 8}

  @doc false
  @spec encode_sfixed64(integer()) :: {binary(), non_neg_integer()}
  def encode_sfixed64(value), do: {<<value::signed-little-64>>, 8}

  @doc false
  @spec encode_fixed32(integer()) :: {binary(), non_neg_integer()}
  def encode_fixed32(value), do: {<<value::little-32>>, 4}

  @doc false
  @spec encode_sfixed32(integer()) :: {binary(), non_neg_integer()}
  def encode_sfixed32(value), do: {<<value::signed-little-32>>, 4}

  @doc false
  @spec encode_double(float() | atom()) :: {binary(), non_neg_integer()}
  def encode_double(:infinity), do: {@positive_infinity_64, 8}
  def encode_double(:"-infinity"), do: {@negative_infinity_64, 8}
  def encode_double(:nan), do: {@nan_64, 8}
  def encode_double(value), do: {<<value::float-little-64>>, 8}

  @doc false
  @spec encode_float(float() | atom()) :: {binary(), non_neg_integer()}
  def encode_float(:infinity), do: {@positive_infinity_32, 4}
  def encode_float(:"-infinity"), do: {@negative_infinity_32, 4}
  def encode_float(:nan), do: {@nan_32, 4}
  def encode_float(value), do: {<<value::float-little-32>>, 4}

  @doc false
  @spec encode_enum(integer()) :: {binary(), non_neg_integer()}
  def encode_enum(value), do: encode_varint_32(value)

  @doc false
  @spec encode_string(String.t()) :: {iodata(), non_neg_integer()}
  def encode_string(value) do
    case Protox.String.validate(value) do
      :ok ->
        {size_varint, size} = Varint.encode(byte_size(value))
        {[size_varint, value], size + byte_size(value)}

      {:error, :invalid_utf8} ->
        raise ArgumentError, message: "String is not valid UTF-8"

      {:error, :too_large} ->
        raise ArgumentError, message: "String is too large"
    end
  end

  @doc false
  @spec encode_bytes(binary()) :: {iodata(), non_neg_integer()}
  def encode_bytes(value) do
    {size_varint, size} = Varint.encode(byte_size(value))
    {[size_varint, value], size + byte_size(value)}
  end

  @doc false
  @spec encode_message(struct()) :: {iodata(), non_neg_integer()}
  def encode_message(value) do
    {value_bytes, value_size} = value.__struct__.encode!(value)
    {value_size_bytes, value_size_bytes_size} = Varint.encode(value_size)

    {[value_size_bytes, value_bytes], value_size + value_size_bytes_size}
  end
end
