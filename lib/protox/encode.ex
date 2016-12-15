defmodule Protox.Encode do

  alias Protox.{
    Default,
    Enumeration,
    Field,
    Message,
    Util,
  }
  import Util
  use Bitwise


  def encode(msg) do
    defs = msg.__struct__.defs()
    Enum.reduce(
      defs.tags,
      <<>>,
      fn (tag, acc) ->
        field = Map.fetch!(defs.fields, tag)
        encode(field.kind, acc, msg, field, tag)
      end)
  end


  # -- Private


  defp encode(:map, acc, msg, field, tag) do
    map = Map.fetch!(msg, field.name)
    if map_size(map) == 0 do
      acc
    else
      Enum.reduce(
        map,
        acc,
        fn ({k, v}, acc) ->
          # Creates a temporary message which acts as map entry.
          # (https://developers.google.com/protocol-buffers/docs/proto3#backwards-compatibility)
          msg = struct!(field.type.name, [{:key, k}, {:value, v}])
          value = encode(msg)
          len = Varint.LEB128.encode(byte_size(value))
          key = make_key_bytes(tag, field.type)
          <<acc::binary, key::binary, len::binary, value::binary>>
        end)
    end
  end


  defp encode({:repeated, :packed}, acc, msg, field = %Field{type: ty}, tag) when is_primitive(ty) do
    case Map.fetch!(msg, field.name) do
      [] ->
        acc

      values ->
        key = Varint.LEB128.encode(tag <<< 3 ||| 2)
        value = encode_packed(values, field)
        <<acc::binary, key::binary, value::binary>>
    end
  end
  defp encode({:repeated, :unpacked}, acc, msg, field, tag) do
    case Map.fetch!(msg, field.name) do
      [] ->
        acc

      values ->
        value = encode_repeated(values, field, tag, field.type)
        <<acc::binary, value::binary>>
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
        value = encode_value(field_value, field)
        <<acc::binary, key::binary, value::binary>>

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
      value = encode_value(field_value, field)
      <<acc::binary, key::binary, value::binary>>
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
    bytes = Enum.reduce(
      values,
      <<>>,
      fn (value, acc) ->
        <<acc::binary, encode_value(value, field)::binary>>
      end)

    <<Varint.LEB128.encode(byte_size(bytes))::binary, bytes::binary>>
  end


  defp encode_repeated(values, field, tag, ty) do
    Enum.reduce(
      values,
      <<>>,
      fn (value, acc) ->
        <<acc::binary, make_key_bytes(tag, ty)::binary, encode_value(value, field)::binary>>
      end)
  end


  defp encode_value(true, _) do
    <<1>>
  end
  defp encode_value(value, %Field{type: ty}) when ty == :sint32 or ty == :sint64 do
    value
    |> Varint.Zigzag.encode()
    |> Varint.LEB128.encode()
  end
  defp encode_value(value, %Field{type: ty}) when ty == :int32 or ty == :int64 do
    <<res::unsigned-native-64>> = <<value::signed-native-64>>
    Varint.LEB128.encode(res)
  end
  defp encode_value(value, %Field{type: ty}) when is_primitive_varint(ty) do
    Varint.LEB128.encode(value)
  end
  defp encode_value(value, %Field{type: :double}) do
    <<value::float-little-64>>
  end
  defp encode_value(value, %Field{type: :float}) do
    <<value::float-little-32>>
  end
  defp encode_value(value, %Field{type: ty}) when ty == :sfixed64 or ty == :fixed64 do
    <<value::little-64>>
  end
  defp encode_value(value, %Field{type: ty}) when ty == :sfixed32 or ty == :fixed32 do
    <<value::little-32>>
  end
  defp encode_value(value, %Field{type: ty}) when ty == :string or ty == :bytes do
    len = Varint.LEB128.encode(byte_size(value))
    <<len::binary, value::binary>>
  end
  defp encode_value(value, %Field{type: %Message{}}) do
    encoded = encode(value)
    len = byte_size(encoded) |> Varint.LEB128.encode()
    <<len::binary, encoded::binary>>
  end
  defp encode_value(value, %Field{type: e = %Enumeration{}}) do
    Varint.LEB128.encode(Map.get(e.values, value, value))
  end

end