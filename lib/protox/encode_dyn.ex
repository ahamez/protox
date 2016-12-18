defmodule Protox.EncodeDyn do

  alias Protox.{
    Default,
    Enumeration,
    Message,
    Util,
  }
  import Util
  use Bitwise


  def encode(msg) do
    defs = msg.__struct__.defs()
    Enum.reduce(
      defs.tags,
      [],
      fn (tag, acc) ->
        field = Map.fetch!(defs.fields, tag)
        encode(field.kind, acc, msg, field, tag)
      end)
  end


  def encode_binary(msg) do
    msg |> encode() |> :binary.list_to_bin()
  end


  # -- Private


  defp encode(:map, acc, msg, field, tag) do
    map = Map.fetch!(msg, field.name)
    if map_size(map) == 0 do
      acc
    else
      # Each key/value entry of a map has the same layout as a message.
      # https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility
      {map_key_type, map_value_type} = field.type
      map_key_key_bytes = make_key_bytes(1, map_key_type)
      map_key_key_len = byte_size(map_key_key_bytes)
      map_value_key_bytes = make_key_bytes(2, map_value_type)
      map_value_key_len = byte_size(map_value_key_bytes)

      Enum.reduce(
        map,
        acc,
        fn ({k, v}, acc) ->

          map_key_value_bytes = encode_value(k, map_key_type)
          map_key_value_len = byte_size(map_key_value_bytes)

          map_value_value_bytes = encode_value(v, map_value_type)
          map_value_value_len = byte_size(map_value_value_bytes)

          len = Varint.LEB128.encode(
            map_key_key_len +
            map_key_value_len + map_value_key_len +
            map_value_value_len
          )
          key = Varint.LEB128.encode(tag <<< 3 ||| 2) # 2: wire type of a message

          [
            acc, key, len,
            map_key_key_bytes, map_key_value_bytes,
            map_value_key_bytes, map_value_value_bytes
          ]
        end)
    end
  end


  defp encode({:repeated, :packed}, acc, msg, field, tag) do
    case Map.fetch!(msg, field.name) do
      [] ->
        acc

      values ->
        key = Varint.LEB128.encode(tag <<< 3 ||| 2)
        value = encode_packed(values, field)
        [acc, key, value]
    end
  end
  defp encode({:repeated, :unpacked}, acc, msg, field, tag) do
    case Map.fetch!(msg, field.name) do
      [] ->
        acc

      values ->
        value = encode_repeated(values, field, tag, field.type)
        [acc, value]
    end
  end


  defp encode({:oneof, parent_field}, acc, msg, field, tag) do
    name = field.name

    case Map.fetch!(msg, parent_field) do
      nil ->
        acc

      # The parent oneof field is set to the current field.
      {^name, field_value} ->
        key = make_key_bytes(tag, field.type)
        value = encode_value(field_value, field.type)
        [acc, key, value]

      _ ->
       acc
    end
  end


  defp encode(:normal, acc, msg, field, tag) do
    field_value = Map.fetch!(msg, field.name)
    if field_value == Default.default(field.type) do
      acc
    else
      key = make_key_bytes(tag, field.type)
      value = encode_value(field_value, field.type)
      [acc, key, value]
    end
  end


  defp make_key_bytes(tag, ty) do
    Varint.LEB128.encode(make_key(tag, ty))
  end


  defp make_key(tag, ty) when is_primitive_varint(ty) , do: tag <<< 3
  defp make_key(tag, %Enumeration{})                  , do: tag <<< 3
  defp make_key(tag, ty) when is_primitive_fixed64(ty), do: tag <<< 3 ||| 1
  defp make_key(tag, ty) when is_delimited(ty)        , do: tag <<< 3 ||| 2
  defp make_key(tag, %Message{})                      , do: tag <<< 3 ||| 2
  defp make_key(tag, ty) when is_primitive_fixed32(ty), do: tag <<< 3 ||| 5


  defp encode_packed(values, field) do
    {bytes, len} = Enum.reduce(
      values,
      {[], 0},
      fn (value, {acc, len}) ->
        value_bytes = encode_value(value, field.type)
        {[acc, value_bytes], len + byte_size(value_bytes)}
      end)

    [Varint.LEB128.encode(len), bytes]
  end


  defp encode_repeated(values, field, tag, ty) do
    key = make_key_bytes(tag, ty)

    Enum.reduce(
      values,
      [],
      fn (value, acc) ->
        [acc, key, encode_value(value, field.type)]
      end)
  end


  defp encode_value(false, _) do
    <<0>>
  end
  defp encode_value(true, _) do
    <<1>>
  end
  defp encode_value(value, ty) when ty == :sint32 or ty == :sint64 do
    value |> Varint.Zigzag.encode() |> Varint.LEB128.encode()
  end
  defp encode_value(value, ty) when ty == :int32 or ty == :int64 do
    <<res::unsigned-native-64>> = <<value::signed-native-64>>
    Varint.LEB128.encode(res)
  end
  defp encode_value(value, ty) when is_primitive_varint(ty) do
    Varint.LEB128.encode(value)
  end
  defp encode_value(value, :double) do
    <<value::float-little-64>>
  end
  defp encode_value(value, :float) do
    <<value::float-little-32>>
  end
  defp encode_value(value, :fixed64) do
    <<value::little-64>>
  end
  defp encode_value(value, :sfixed64) do
    <<value::signed-little-64>>
  end
  defp encode_value(value, :fixed32) do
    <<value::little-32>>
  end
  defp encode_value(value, :sfixed32) do
    <<value::signed-little-32>>
  end
  defp encode_value(value, ty) when ty == :string or ty == :bytes do
    len = Varint.LEB128.encode(byte_size(value))
    <<len::binary, value::binary>>
  end
  defp encode_value(value, %Message{}) do
    encoded = encode_binary(value)
    len = byte_size(encoded) |> Varint.LEB128.encode()
    <<len::binary, encoded::binary>>
  end
  defp encode_value(value, e = %Enumeration{}) do
    Varint.LEB128.encode(Map.get(e.values, value, value))
  end

end
