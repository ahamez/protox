defmodule Protox.Encode do

  @moduledoc false
  # Internal. Functions to encode types.

  import Protox.Guards
  use Bitwise


  @spec encode(struct) :: iodata
  def encode(msg) do
    msg.__struct__.encode(msg)
  end


  @spec make_key_bytes(Protox.Types.tag, Protox.Types.type) :: iodata
  def make_key_bytes(tag, ty) do
    Protox.Varint.encode(make_key(tag, ty))
  end


  @spec make_key(Protox.Types.tag, Protox.Types.type) :: non_neg_integer
  def make_key(tag, ty) when is_primitive_varint(ty) , do: tag <<< 3
  def make_key(tag, {:enum, _})                      , do: tag <<< 3
  def make_key(tag, ty) when is_primitive_fixed64(ty), do: tag <<< 3 ||| 1
  def make_key(tag, ty) when is_delimited(ty)        , do: tag <<< 3 ||| 2
  def make_key(tag, {:message, _})                   , do: tag <<< 3 ||| 2
  def make_key(tag, :packed)                         , do: tag <<< 3 ||| 2
  def make_key(tag, :map_entry)                      , do: tag <<< 3 ||| 2
  def make_key(tag, ty) when is_primitive_fixed32(ty), do: tag <<< 3 ||| 5


  @spec encode_varint_signed(integer) :: iodata
  def encode_varint_signed(value) do
    value |> Varint.Zigzag.encode() |> Protox.Varint.encode()
  end


  @spec encode_varint_64(integer) :: iodata
  def encode_varint_64(value) do
    <<res::unsigned-native-64>> = <<value::signed-native-64>>
    Protox.Varint.encode(res)
  end


  @spec encode_varint_32(integer) :: iodata
  def encode_varint_32(value) do
    <<res::unsigned-native-32>> = <<value::signed-native-32>>
    Protox.Varint.encode(res)
  end


  @spec encode_bool(boolean) :: binary
  def encode_bool(false), do: <<0>>
  def encode_bool(true), do: <<1>>


  @spec encode_int32(integer) :: iodata
  def encode_int32(value), do: encode_varint_32(value)


  @spec encode_int64(integer) :: iodata
  def encode_int64(value), do: encode_varint_64(value)


  @spec encode_sint32(integer) :: iodata
  def encode_sint32(value), do: encode_varint_signed(value)


  @spec encode_sint64(integer) :: iodata
  def encode_sint64(value), do: encode_varint_signed(value)


  @spec encode_uint32(non_neg_integer) :: iodata
  def encode_uint32(value), do: encode_varint_32(value)


  @spec encode_uint64(non_neg_integer) :: iodata
  def encode_uint64(value), do: encode_varint_64(value)


  @spec encode_fixed64(integer) :: binary
  def encode_fixed64(value), do: <<value::little-64>>


  @spec encode_sfixed64(integer) :: binary
  def encode_sfixed64(value), do: <<value::signed-little-64>>


  @spec encode_fixed32(integer) :: binary
  def encode_fixed32(value), do: <<value::little-32>>


  @spec encode_sfixed32(integer) :: binary
  def encode_sfixed32(value), do: <<value::signed-little-32>>


  @spec encode_double(float) :: binary
  def encode_double(value), do: <<value::float-little-64>>


  @spec encode_float(float) :: binary
  def encode_float(value), do: <<value::float-little-32>>


  # Even if the documentation says otherwise, the C++ reference
  # implementation encodes enums on 64 bits.
  @spec encode_enum(integer) :: iodata
  def encode_enum(value), do: encode_varint_64(value)


  @spec encode_string(String.t) :: iodata
  def encode_string(value) do
    [Protox.Varint.encode(byte_size(value)), value]
  end


  @spec encode_bytes(binary) :: iodata
  def encode_bytes(value) do
    [Protox.Varint.encode(byte_size(value)), value]
  end


  @spec encode_message(struct) :: iodata
  def encode_message(value) do
    encoded = value |> encode() |> :binary.list_to_bin()
    [Protox.Varint.encode(byte_size(encoded)), encoded]
  end

end
