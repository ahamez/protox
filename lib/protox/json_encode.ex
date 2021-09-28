defmodule Protox.JsonEncode do
  @moduledoc false

  alias Protox.Field

  use Protox.Float

  @spec encode!(struct(), fun()) :: iodata()
  def encode!(msg, json_encode) do
    Protox.JsonMessageEncoder.encode_message(msg, json_encode)
  end

  def encode_message(msg, json_encode) do
    initial_acc = ["}"]

    body =
      msg.__struct__.fields_defs()
      |> Enum.reduce(initial_acc, fn %Protox.Field{} = field, acc ->
        case encode_msg_field(msg, field, json_encode) do
          <<>> ->
            acc

          encoded ->
            case acc do
              ^initial_acc -> [encoded | acc]
              _ -> [encoded, "," | acc]
            end
        end
      end)

    ["{" | body]
  end

  def encode_enum(_enum, value, json_encode) when is_atom(value) do
    json_encode.(value)
  end

  def encode_enum(enum, value, json_encode) do
    value |> enum.__struct__.decode() |> json_encode.()
  end

  def encode_value(value, :bytes, _json_encode), do: "\"#{Base.url_encode64(value)}\""

  def encode_value(:infinity, _type, _json_encode), do: "\"Infinity\""
  def encode_value(:"-infinity", _type, _json_encode), do: "\"-Infinity\""
  def encode_value(:nan, _type, _json_encode), do: "\"NaN\""

  def encode_value(value, :int64, _json_encode), do: "\"#{value}\""
  def encode_value(value, :uint64, _json_encode), do: "\"#{value}\""
  def encode_value(value, :fixed64, _json_encode), do: "\"#{value}\""
  def encode_value(value, :sfixed64, _json_encode), do: "\"#{value}\""

  def encode_value(true, :bool, _json_encode), do: "true"

  def encode_value(value, {:enum, enum}, json_encode) do
    Protox.JsonEnumEncoder.encode_enum(struct(enum), value, json_encode)
  end

  def encode_value(value, {:message, _}, json_encode) do
    Protox.JsonMessageEncoder.encode_message(value, json_encode)
  end

  def encode_value(value, _type, json_encode), do: json_encode.(value)

  # -- Private

  defp encode_msg_field(
         msg,
         %Field{name: child_name, kind: {:oneof, parent_name}} = field,
         json_encode
       ) do
    case Map.fetch!(msg, parent_name) do
      {^child_name, field_value} ->
        json_value = encode_value(field_value, field.type, json_encode)
        [json_encode.(field.json_name), ":", json_value]

      _ ->
        <<>>
    end
  end

  defp encode_msg_field(msg, %Field{} = field, json_encode) do
    field_value = Map.fetch!(msg, field.name)
    json_value = encode_field(field, field_value, json_encode, msg.__struct__.syntax())

    case json_value do
      <<>> -> <<>>
      _ -> [json_encode.(field.json_name), ":", json_value]
    end
  end

  defp encode_field(%Field{label: :repeated}, [], _json_encode, _syntax), do: <<>>

  defp encode_field(%Field{label: :repeated, type: type}, value, json_encode, _syntax) do
    initial_acc = ["]"]

    res =
      value
      |> Enum.reverse()
      |> Enum.reduce(initial_acc, fn v, acc ->
        v_json = encode_value(v, type, json_encode)

        case acc do
          ^initial_acc -> [v_json | acc]
          _ -> [v_json, "," | acc]
        end
      end)

    ["[" | res]
  end

  defp encode_field(%Field{}, nil, _json_encode, _syntax) do
    <<>>
  end

  defp encode_field(%Field{kind: {:scalar, default_value}}, value, _json_encode, :proto3)
       when value == default_value do
    <<>>
  end

  defp encode_field(
         %Field{kind: {:scalar, _default_value}, type: type},
         value,
         json_encode,
         _syntax
       ) do
    encode_value(value, type, json_encode)
  end

  defp encode_field(%Field{kind: :map}, value, _json_encode, _syntax) when map_size(value) == 0,
    do: <<>>

  defp encode_field(
         %Field{kind: :map, type: {_key_type, value_type}},
         value,
         json_encode,
         _syntax
       ) do
    initial_acc = ["}"]

    res =
      Enum.reduce(value, initial_acc, fn {k, v}, acc ->
        k_json = k |> to_string() |> json_encode.()
        v_json = encode_value(v, value_type, json_encode)

        case acc do
          ^initial_acc -> [k_json, ":", v_json | acc]
          _ -> [k_json, ":", v_json, "," | acc]
        end
      end)

    ["{" | res]
  end
end
