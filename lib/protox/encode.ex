defmodule Protox.Encode do

  @moduledoc false
  # Internal. Functions to encode types.

  import Protox.Guards
  use Bitwise


  @spec encode(struct) :: iolist
  def encode(msg) do
    msg.__struct__.encode(msg)
  end


  def make_key_bytes(tag, ty) do
    Varint.LEB128.encode(make_key(tag, ty))
  end


  def make_key(tag, ty) when is_primitive_varint(ty) , do: tag <<< 3
  def make_key(tag, {:enum, _})                      , do: tag <<< 3
  def make_key(tag, ty) when is_primitive_fixed64(ty), do: tag <<< 3 ||| 1
  def make_key(tag, ty) when is_delimited(ty)        , do: tag <<< 3 ||| 2
  def make_key(tag, {:message, _})                   , do: tag <<< 3 ||| 2
  def make_key(tag, :packed)                         , do: tag <<< 3 ||| 2
  def make_key(tag, :map_entry)                      , do: tag <<< 3 ||| 2
  def make_key(tag, ty) when is_primitive_fixed32(ty), do: tag <<< 3 ||| 5


  def encode_varint_signed(value) do
    value |> Varint.Zigzag.encode() |> Varint.LEB128.encode()
  end
  def encode_varint(value) do
    <<res::unsigned-native-64>> = <<value::signed-native-64>>
    Varint.LEB128.encode(res)
  end
  def encode_varint_unsigned(value) do
    Varint.LEB128.encode(value)
  end


  def encode_bool(false)    , do: <<0>>
  def encode_bool(true)     , do: <<1>>
  def encode_int32(value)   , do: encode_varint(value)
  def encode_int64(value)   , do: encode_varint(value)
  def encode_sint32(value)  , do: encode_varint_signed(value)
  def encode_sint64(value)  , do: encode_varint_signed(value)
  def encode_uint32(value)  , do: encode_varint_unsigned(value)
  def encode_uint64(value)  , do: encode_varint_unsigned(value)
  def encode_fixed64(value) , do: <<value::little-64>>
  def encode_sfixed64(value), do: <<value::signed-little-64>>
  def encode_fixed32(value) , do: <<value::little-32>>
  def encode_sfixed32(value), do: <<value::signed-little-32>>
  def encode_double(value)  , do: <<value::float-little-64>>
  def encode_float(value)   , do: <<value::float-little-32>>
  def encode_enum(value)    , do: encode_varint_unsigned(value)
  def encode_string(value) do
    len = Varint.LEB128.encode(byte_size(value))
    <<len::binary, value::binary>>
  end
  def encode_bytes(value) do
    len = Varint.LEB128.encode(byte_size(value))
    <<len::binary, value::binary>>
  end
  def encode_message(value) do
    encoded = value |> encode() |> :binary.list_to_bin()
    len = encoded |> byte_size() |> Varint.LEB128.encode()
    <<len::binary, encoded::binary>>
  end

end
