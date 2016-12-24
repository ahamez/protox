defmodule Protox.Decode do

  @moduledoc """
  Decodes a binary into a message.
  """


  import Protox.Guards
  use Bitwise


  def decode!(bytes, mod) do
    parse_key_value(bytes, mod.defs(), struct(mod.__struct__))
  end


  def decode(bytes, mod) do
    try do
      {:ok, decode!(bytes, mod)}
    rescue
      e -> {:error, e}
    end
  end


  # -- Private


  defmodule MapEntry do
    @moduledoc false

    defstruct key: nil,
              value: nil
  end


  defp parse_key_value(<<>>, _, msg) do
    msg
  end
  defp parse_key_value(bytes, defs, msg) do
    {tag, wire_type, rest} = parse_key(bytes)

    field = defs[tag]
    {new_msg, new_rest} = if field do
      {name, kind, type} = field
      {value, new_rest} = parse_value(rest, wire_type, type)
      {set_field(msg, name, kind, value), new_rest}
    else
      # TODO. Keep unknown bytes?
      {msg, parse_unknown(wire_type, rest)}
    end

    parse_key_value(new_rest, defs, new_msg)
  end


  # Get the key's tag and wire type.
  defp parse_key(bytes) do
    {key, rest} = Varint.LEB128.decode(bytes)
    {key >>> 3, key &&& 0b111, rest}
  end


  # Wire type 0: varint.
  defp parse_value(bytes, 0, type) do
    {value, rest} = Varint.LEB128.decode(bytes)
    {varint_value(value, type), rest}
  end


  # Wire type 1: fixed 64-bit.
  defp parse_value(<<value::float-little-64, rest::binary>>, 1, :double) do
    {value, rest}
  end
  defp parse_value(<<value::little-64, rest::binary>>, 1, :fixed64) do
    {value, rest}
  end
  defp parse_value(<<value::signed-little-64, rest::binary>>, 1, :sfixed64) do
    {value, rest}
  end


  # Wire type 2: length-delimited.
  defp parse_value(bytes, 2, type) do
    {len, new_bytes} = Varint.LEB128.decode(bytes)
    <<delimited::binary-size(len), rest::binary>> = new_bytes
    {parse_delimited(delimited, type), rest}
  end


  # Wire type 5: fixed 32-bit.
  defp parse_value(<<value::float-little-32, rest::binary>>, 5, :float) do
    {value, rest}
  end
  defp parse_value(<<value::little-32, rest::binary>>, 5, :fixed32) do
    {value, rest}
  end
  defp parse_value(<<value::signed-little-32, rest::binary>>, 5, :sfixed32) do
    {value, rest}
  end


  defp parse_delimited(bytes, type) when is_primitive_varint(type) do
    parse_repeated_varint([], bytes, type)
  end
  defp parse_delimited(bytes, type) when is_primitive_fixed(type) do
    parse_repeated_fixed([], bytes, type)
  end
  defp parse_delimited(bytes, type) when type == :string or type == :bytes do
    bytes
  end
  defp parse_delimited(bytes, type = {:enum, _}) do
    parse_repeated_varint([], bytes, type)
  end
  defp parse_delimited(bytes, {:message, name}) do
    decode!(bytes, name)
  end
  defp parse_delimited(bytes, {map_key_type, map_value_type}) do
    defs = %{
      1 => {:key, {:default, :dummy}, map_key_type},
      2 => {:value, {:default, :dummy}, map_value_type},
    }

    %MapEntry{key: map_key, value: map_value} = parse_key_value(bytes, defs, %MapEntry{})
    {map_key, map_value}
  end


  defp parse_repeated_varint(acc, <<>>, _) do
    Enum.reverse(acc)
  end
  defp parse_repeated_varint(acc, bytes, type) do
    {value, rest} = Varint.LEB128.decode(bytes)
    parse_repeated_varint([varint_value(value, type)|acc], rest, type)
  end


  defp parse_repeated_fixed(acc, <<>>, _) do
    Enum.reverse(acc)
  end
  defp parse_repeated_fixed(acc, <<value::signed-little-64, rest::binary>>, ty)
  when ty == :fixed64 or ty == :sfixed64 do
    parse_repeated_fixed([value|acc], rest, ty)
  end
  defp parse_repeated_fixed(acc, <<value::signed-little-32, rest::binary>>, ty)
  when ty == :fixed32 or ty == :sfixed32 do
    parse_repeated_fixed([value|acc], rest, ty)
  end
  defp parse_repeated_fixed(acc, <<value::float-little-64, rest::binary>>, :double) do
    parse_repeated_fixed([value|acc], rest, :double)
  end
  defp parse_repeated_fixed(acc, <<value::float-little-32, rest::binary>>, :float) do
    parse_repeated_fixed([value|acc], rest, :float)
  end


  defp varint_value(value, :bool)       , do: value == 1
  defp varint_value(value, :sint32)     , do: Varint.Zigzag.decode(value)
  defp varint_value(value, :sint64)     , do: Varint.Zigzag.decode(value)
  defp varint_value(value, :uint32)     , do: value
  defp varint_value(value, :uint64)     , do: value
  defp varint_value(value, {:enum, mod}), do: mod.decode(value)
  defp varint_value(value, :int32) do
    <<res::signed-32>> = <<value::32>>
    res
  end
  defp varint_value(value, :int64) do
    <<res::signed-64>> = <<value::64>>
    res
  end


  defp parse_unknown(0, bytes)                  , do: get_varint_bytes(bytes)
  defp parse_unknown(1, <<_::64, rest::binary>>), do: rest
  defp parse_unknown(5, <<_::32, rest::binary>>), do: rest
  defp parse_unknown(2, bytes) do
    {len, new_bytes} = Varint.LEB128.decode(bytes)
    <<_::binary-size(len), rest::binary>> = new_bytes
    rest
  end


  defp get_varint_bytes(<<0::1, _::7, rest::binary>>), do: rest
  defp get_varint_bytes(<<1::1, _::7, rest::binary>>), do: get_varint_bytes(rest)


  # Set the field correponding to `tag` in `msg` with `value`.
  defp set_field(msg, name, kind, value) do
    {f, v} = case kind do
      :map ->
        previous = Map.fetch!(msg, name)
        {name, Map.put(previous, elem(value, 0), elem(value, 1))}

      {:oneof, parent_field} ->
        {parent_field, {name, value}}

      {:default, _} ->
        {name, value}

      _ -> # repeated
        previous = Map.fetch!(msg, name)
        {name, previous ++ List.wrap(value)}
    end

    struct!(msg, [{f, v}])
  end

end
