defmodule Protox.Decode do
  @moduledoc false
  # Decodes a binary into a message.

  use Bitwise
  use Protox.Float
  use Protox.WireTypes

  alias Protox.{
    Types,
    Varint,
    Zigzag
  }

  @spec decode!(binary, atom, [atom]) :: struct | no_return
  def decode!(bytes, mod, required_fields) do
    {msg, set_fields} = parse_key_value([], bytes, mod.defs(), struct(mod.__struct__))

    case required_fields -- set_fields do
      [] -> msg
      missing_fields -> raise Protox.RequiredFieldsError.new(missing_fields)
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
              __uf__: []

    @spec unknown_fields_name() :: :__uf__
    def unknown_fields_name(), do: :__uf__
  end

  @spec parse_key_value([atom], binary, map, struct) :: {struct, [atom]}
  defp parse_key_value(set_fields, <<>>, _, msg) do
    {msg, set_fields}
  end

  defp parse_key_value(set_fields, bytes, defs, msg) do
    {tag, wire_type, rest} = parse_key(bytes)

    if tag == 0 do
      raise "Illegal field with tag 0"
    end

    field_def = defs[tag]

    {new_set_fields, new_msg, new_rest} =
      if field_def do
        {name, kind, type} = field_def
        {value, new_rest} = parse_value(rest, wire_type, type)
        field = update_field(msg, name, kind, value, type)
        msg_updated = struct!(msg, [field])
        {[name | set_fields], msg_updated, new_rest}
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

  @spec parse_value(binary, Types.tag(), Types.type()) :: {any, binary}
  defp parse_value(bytes, @wire_delimited, type) do
    {len, new_bytes} = Varint.decode(bytes)
    <<delimited::binary-size(len), rest::binary>> = new_bytes
    {parse_delimited(delimited, type), rest}
  end

  defp parse_value(bytes, _, type) do
    parse_single(bytes, type)
  end

  @spec parse_single(binary, atom) :: {any, binary}
  defp parse_single(<<@positive_infinity_64, rest::binary>>, :double) do
    {:infinity, rest}
  end

  defp parse_single(<<@negative_infinity_64, rest::binary>>, :double) do
    {:"-infinity", rest}
  end

  defp parse_single(<<_::48, 0b1111::4, _::4, _::1, 0b1111111::7, rest::binary>>, :double) do
    {:nan, rest}
  end

  defp parse_single(<<value::float-little-64, rest::binary>>, :double) do
    {value, rest}
  end

  defp parse_single(<<value::signed-little-64, rest::binary>>, :sfixed64) do
    {value, rest}
  end

  defp parse_single(<<value::signed-little-64, rest::binary>>, :fixed64) do
    {value, rest}
  end

  defp parse_single(<<@positive_infinity_32, rest::binary>>, :float) do
    {:infinity, rest}
  end

  defp parse_single(<<@negative_infinity_32, rest::binary>>, :float) do
    {:"-infinity", rest}
  end

  defp parse_single(<<_::16, 1::1, _::7, _::1, 0b1111111::7, rest::binary>>, :float) do
    {:nan, rest}
  end

  defp parse_single(<<value::float-little-32, rest::binary>>, :float) do
    {value, rest}
  end

  defp parse_single(<<value::signed-little-32, rest::binary>>, :sfixed32) do
    {value, rest}
  end

  defp parse_single(<<value::signed-little-32, rest::binary>>, :fixed32) do
    {value, rest}
  end

  defp parse_single(bytes, type) do
    {value, rest} = Varint.decode(bytes)
    {varint_value(value, type), rest}
  end

  defp parse_delimited(bytes, :string), do: bytes
  defp parse_delimited(bytes, :bytes), do: bytes
  defp parse_delimited(bytes, type = {:enum, _}), do: parse_repeated_varint([], bytes, type)
  defp parse_delimited(bytes, {:message, m}), do: decode!(bytes, m, m.required_fields())
  defp parse_delimited(bytes, :int32), do: parse_repeated_varint([], bytes, :int32)
  defp parse_delimited(bytes, :uint32), do: parse_repeated_varint([], bytes, :uint32)
  defp parse_delimited(bytes, :sint32), do: parse_repeated_varint([], bytes, :sint32)
  defp parse_delimited(bytes, :int64), do: parse_repeated_varint([], bytes, :int64)
  defp parse_delimited(bytes, :uint64), do: parse_repeated_varint([], bytes, :uint64)
  defp parse_delimited(bytes, :sint64), do: parse_repeated_varint([], bytes, :sint64)
  defp parse_delimited(bytes, :bool), do: parse_repeated_varint([], bytes, :bool)
  defp parse_delimited(bytes, :fixed32), do: parse_repeated_fixed([], bytes, :fixed32)
  defp parse_delimited(bytes, :sfixed32), do: parse_repeated_fixed([], bytes, :sfixed32)
  defp parse_delimited(bytes, :float), do: parse_repeated_fixed([], bytes, :float)
  defp parse_delimited(bytes, :fixed64), do: parse_repeated_fixed([], bytes, :fixed64)
  defp parse_delimited(bytes, :sfixed64), do: parse_repeated_fixed([], bytes, :sfixed64)
  defp parse_delimited(bytes, :double), do: parse_repeated_fixed([], bytes, :double)

  defp parse_delimited(bytes, {map_key_type, map_value_type}) do
    defs = %{
      1 => {:key, {:default, :dummy}, map_key_type},
      2 => {:value, {:default, :dummy}, map_value_type}
    }

    {%MapEntry{key: map_key, value: map_value}, _} = parse_key_value([], bytes, defs, %MapEntry{})

    map_key =
      case map_key do
        nil -> Protox.Default.default(map_key_type)
        _ -> map_key
      end

    map_value =
      case {map_value, map_value_type} do
        {nil, {:message, msg_ty}} -> struct!(msg_ty)
        {nil, _} -> Protox.Default.default(map_value_type)
        _ -> map_value
      end

    {map_key, map_value}
  end

  defp parse_repeated_varint(acc, <<>>, _) do
    Enum.reverse(acc)
  end

  defp parse_repeated_varint(acc, bytes, type) do
    {value, rest} = Varint.decode(bytes)
    parse_repeated_varint([varint_value(value, type) | acc], rest, type)
  end

  defp parse_repeated_fixed(acc, <<>>, _) do
    Enum.reverse(acc)
  end

  defp parse_repeated_fixed(acc, bytes, type) do
    {value, rest} = parse_single(bytes, type)
    parse_repeated_fixed([value | acc], rest, type)
  end

  @spec varint_value(non_neg_integer, atom) :: integer
  defp varint_value(value, :bool), do: value != 0

  defp varint_value(value, :sint32) do
    <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
    Zigzag.decode(res)
  end

  defp varint_value(value, :sint64) do
    <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
    Zigzag.decode(res)
  end

  defp varint_value(value, :uint32) do
    <<res::unsigned-native-32>> = <<value::unsigned-native-32>>
    res
  end

  defp varint_value(value, :uint64) do
    <<res::unsigned-native-64>> = <<value::unsigned-native-64>>
    res
  end

  defp varint_value(value, {:enum, mod}) do
    <<res::signed-native-32>> = <<value::signed-native-32>>
    mod.decode(res)
  end

  defp varint_value(value, :int32) do
    <<res::signed-native-32>> = <<value::signed-native-32>>
    res
  end

  defp varint_value(value, :int64) do
    <<res::signed-native-64>> = <<value::signed-native-64>>
    res
  end

  @spec parse_unknown(struct, non_neg_integer, Types.tag(), binary) :: {struct, binary}
  def parse_unknown(msg, tag, @wire_varint, bytes) do
    {unknown_bytes, rest} = get_unknown_varint_bytes(<<>>, bytes)
    {add_unknown_field(msg, tag, @wire_varint, unknown_bytes), rest}
  end

  def parse_unknown(msg, tag, @wire_64bits, <<unknown_bytes::64, rest::binary>>) do
    {add_unknown_field(msg, tag, @wire_64bits, <<unknown_bytes::64>>), rest}
  end

  def parse_unknown(msg, tag, @wire_delimited, bytes) do
    {len, new_bytes} = Varint.decode(bytes)
    <<unknown_bytes::binary-size(len), rest::binary>> = new_bytes
    {add_unknown_field(msg, tag, @wire_delimited, unknown_bytes), rest}
  end

  def parse_unknown(msg, tag, @wire_32bits, <<unknown_bytes::32, rest::binary>>) do
    {add_unknown_field(msg, tag, @wire_32bits, <<unknown_bytes::32>>), rest}
  end

  defp get_unknown_varint_bytes(acc, <<0::1, b::7, rest::binary>>) do
    {<<acc::binary, 0::1, b::7>>, rest}
  end

  defp get_unknown_varint_bytes(acc, <<1::1, b::7, rest::binary>>) do
    get_unknown_varint_bytes(<<acc::binary, 1::1, b::7>>, rest)
  end

  defp add_unknown_field(msg, tag, wire_type, bytes) do
    unknown_fields_name = msg.__struct__.unknown_fields_name()
    previous = Map.fetch!(msg, unknown_fields_name)
    struct!(msg, [{unknown_fields_name, [{tag, wire_type, bytes} | previous]}])
  end

  # Set the field `name` in `msg` with `value`.
  defp update_field(msg, name, :map, value, _type) do
    previous = Map.fetch!(msg, name)
    {entry_key, entry_value} = value

    {name, Map.put(previous, entry_key, entry_value)}
  end

  defp update_field(msg, name, {:oneof, parent_field}, value, type) do
    case type do
      {:message, _} ->
        case Map.fetch!(msg, parent_field) do
          {^name, previous_value} ->
            {parent_field, {name, Protox.Message.merge(previous_value, value)}}

          _ ->
            {parent_field, {name, value}}
        end

      _ ->
        {parent_field, {name, value}}
    end
  end

  defp update_field(msg, name, {:default, _}, value, type) do
    case type do
      {:message, _} ->
        case Map.fetch!(msg, name) do
          nil -> {name, value}
          previous -> {name, Protox.Message.merge(previous, value)}
        end

      _ ->
        {name, value}
    end
  end

  # repeated
  defp update_field(msg, name, _kind, value, _type) do
    previous = Map.fetch!(msg, name)

    {name, previous ++ List.wrap(value)}
  end
end
