defmodule Protox.Decode do

  @moduledoc false
  # Decodes a binary into a message.

  use Bitwise
  alias Protox.{
    Varint,
    Zigzag,
  }


  @spec decode!(binary, atom, [atom]) :: struct | no_return
  def decode!(bytes, mod, required_fields) do
    {msg, set_fields} = parse_key_value([], bytes, mod.defs(), struct(mod.__struct__))

    case required_fields -- set_fields  do
      []             ->  msg
      missing_fields -> raise "Missing required fields #{inspect missing_fields}"
    end
  end


  @spec decode(binary, atom, [atom]) :: {:ok, struct} | {:error, any}
  def decode(bytes, mod, required_fields) do
    try do
      {:ok, decode!(bytes, mod, required_fields)}
    rescue
      e -> {:error, e}
    end
  end


  # -- Private


  defmodule MapEntry do
    @moduledoc false

    defstruct key: nil,
              value: nil,
              __unknown_fields__: []

    @spec get_unknown_fields_name() :: :__unknown_fields__
    def get_unknown_fields_name(), do: :__unknown_fields__
  end


  @spec parse_key_value([atom], binary, map, struct) :: {struct, [atom]}
  defp parse_key_value(set_fields, <<>>, _, msg) do
    {msg, set_fields}
  end
  defp parse_key_value(set_fields, bytes, defs, msg) do
    {tag, wire_type, rest} = parse_key(bytes)

    field = defs[tag]
    {new_set_fields, new_msg, new_rest} = if field do
      {name, kind, type} = field
      {value, new_rest} = parse_value(rest, wire_type, type)
      {[elem(field, 0)| set_fields], set_field(msg, name, kind, value), new_rest}
    else
      {new_msg, new_rest} = parse_unknown(msg, tag, wire_type, rest)
      {set_fields, new_msg, new_rest}
    end

    parse_key_value(new_set_fields, new_rest, defs, new_msg)
  end


  # Get the key's tag and wire type.
  @spec parse_key(binary) :: {non_neg_integer, non_neg_integer, binary}
  def parse_key(bytes) do
    {key, rest} = Varint.decode(bytes)
    {key >>> 3, key &&& 0b111, rest}
  end


  @spec parse_value(binary, 0 | 1 | 2 | 5, atom) :: {any, binary}

  # Wire type 0: varint.
  defp parse_value(bytes, 0, type) do
    {value, rest} = Varint.decode(bytes)
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
    {len, new_bytes} = Varint.decode(bytes)
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


  defp parse_delimited(bytes, :string)          , do: bytes
  defp parse_delimited(bytes, :bytes)           , do: bytes
  defp parse_delimited(bytes, type = {:enum, _}), do: parse_repeated_varint([], bytes, type)
  defp parse_delimited(bytes, {:message, m})    , do: decode!(bytes, m, m.get_required_fields())
  defp parse_delimited(bytes, :int32)           , do: parse_repeated_varint([], bytes, :int32)
  defp parse_delimited(bytes, :uint32)          , do: parse_repeated_varint([], bytes, :uint32)
  defp parse_delimited(bytes, :sint32)          , do: parse_repeated_varint([], bytes, :sint32)
  defp parse_delimited(bytes, :int64)           , do: parse_repeated_varint([], bytes, :int64)
  defp parse_delimited(bytes, :uint64)          , do: parse_repeated_varint([], bytes, :uint64)
  defp parse_delimited(bytes, :sint64)          , do: parse_repeated_varint([], bytes, :sint64)
  defp parse_delimited(bytes, :bool)            , do: parse_repeated_varint([], bytes, :bool)
  defp parse_delimited(bytes, :fixed32)         , do: parse_repeated_fixed([], bytes, :fixed32)
  defp parse_delimited(bytes, :sfixed32)        , do: parse_repeated_fixed([], bytes, :sfixed32)
  defp parse_delimited(bytes, :float)           , do: parse_repeated_fixed([], bytes, :float)
  defp parse_delimited(bytes, :fixed64)         , do: parse_repeated_fixed([], bytes, :fixed64)
  defp parse_delimited(bytes, :sfixed64)        , do: parse_repeated_fixed([], bytes, :sfixed64)
  defp parse_delimited(bytes, :double)          , do: parse_repeated_fixed([], bytes, :double)
  defp parse_delimited(bytes, {map_key_type, map_value_type}) do
    defs = %{
      1 => {:key, {:default, :dummy}, map_key_type},
      2 => {:value, {:default, :dummy}, map_value_type},
    }

    {%MapEntry{key: map_key, value: map_value}, _} = parse_key_value([], bytes, defs, %MapEntry{})

    map_key2 = case map_key do
      nil -> Protox.Default.default(map_key_type)
      _   -> map_key
    end

    map_value2 = case map_value do
      nil -> Protox.Default.default(map_value_type)
      _   -> map_value
    end

    {map_key2, map_value2}
  end


  defp parse_repeated_varint(acc, <<>>, _) do
    Enum.reverse(acc)
  end
  defp parse_repeated_varint(acc, bytes, type) do
    {value, rest} = Varint.decode(bytes)
    parse_repeated_varint([varint_value(value, type)|acc], rest, type)
  end


  defp parse_repeated_fixed(acc, <<value::float-little-64, rest::binary>>, :double) do
    parse_repeated_fixed([value|acc], rest, :double)
  end
  defp parse_repeated_fixed(acc, <<value::float-little-32, rest::binary>>, :float) do
    parse_repeated_fixed([value|acc], rest, :float)
  end
  defp parse_repeated_fixed(acc, <<value::signed-little-64, rest::binary>>, ty)
  when ty == :fixed64 or ty == :sfixed64 do
    parse_repeated_fixed([value|acc], rest, ty)
  end
  defp parse_repeated_fixed(acc, <<value::signed-little-32, rest::binary>>, ty)
  when ty == :fixed32 or ty == :sfixed32 do
    parse_repeated_fixed([value|acc], rest, ty)
  end
  defp parse_repeated_fixed(acc, <<>>, _) do
    Enum.reverse(acc)
  end


  @spec varint_value(non_neg_integer, atom) :: integer
  defp varint_value(value, :bool)       , do: value == 1
  defp varint_value(value, :sint32)     , do: Zigzag.decode(value)
  defp varint_value(value, :sint64)     , do: Zigzag.decode(value)
  defp varint_value(value, :uint32)     , do: value
  defp varint_value(value, :uint64)     , do: value
  defp varint_value(value, {:enum, mod}) do
    <<res::signed-64>> = <<value::64>>
    mod.decode(res)
  end
  defp varint_value(value, :int32) do
    <<res::signed-32>> = <<value::32>>
    res
  end
  defp varint_value(value, :int64) do
    <<res::signed-64>> = <<value::64>>
    res
  end


  @spec parse_unknown(struct, non_neg_integer, 0 | 1 | 2 | 5, binary) :: {struct, binary}
  def parse_unknown(msg, tag, 0, bytes) do
    {unknown_bytes, rest} = get_unknown_varint_bytes(<<>>, bytes)
    {add_unknown_field(msg, tag, 0, unknown_bytes), rest}
  end
  def parse_unknown(msg, tag, 1, <<unknown_bytes::64, rest::binary>>) do
    {add_unknown_field(msg, tag, 1, <<unknown_bytes::64>>), rest}
  end
  def parse_unknown(msg, tag, 2, bytes) do
    {len, new_bytes} = Varint.decode(bytes)
    <<unknown_bytes::binary-size(len), rest::binary>> = new_bytes
    {add_unknown_field(msg, tag, 2, unknown_bytes), rest}
  end
  def parse_unknown(msg, tag, 5, <<unknown_bytes::32, rest::binary>>) do
    {add_unknown_field(msg, tag, 5, <<unknown_bytes::32>>), rest}
  end


  defp get_unknown_varint_bytes(acc, <<0::1, b::7, rest::binary>>) do
    {<<acc::binary, 0::1, b::7>>, rest}
  end
  defp get_unknown_varint_bytes(acc, <<1::1, b::7, rest::binary>>) do
    get_unknown_varint_bytes(<<acc::binary, 1::1, b::7>>, rest)
  end


  defp add_unknown_field(msg, tag, wire_type, bytes) do
    unknown_fields_name = msg.__struct__.get_unknown_fields_name()
    previous = Map.fetch!(msg, unknown_fields_name)
    struct!(msg, [{unknown_fields_name, [{tag, wire_type, bytes} | previous]}])
  end


  # Set the field correponding to `tag` in `msg` with `value`.
  defp set_field(msg, name, kind, value) do
    field_value = case kind do
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

    struct!(msg, [field_value])
  end

end
