defmodule Protox.JsonEncode do
  @doc """
  TODO
  """

  alias Protox.Field

  use Protox.Float

  @spec encode!(struct()) :: iodata()
  def encode!(msg) do
    initial_acc = ["}"]

    body =
      msg.__struct__.fields()
      |> Enum.reduce(initial_acc, fn %Field{} = field, acc ->
        case encode_msg_field(msg, field) do
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

  defp encode_msg_field(_msg, %Field{kind: {:oneof, _parent}}) do
    # TODO
    <<>>
  end

  defp encode_msg_field(msg, %Field{} = field) do
    field_value = Map.fetch!(msg, field.name)
    json_value = encode_field(field, field_value)

    case json_value do
      <<>> -> <<>>
      _ -> [json_encode(field.json_name), ":", json_value]
    end
  end

  defp encode_field(%Field{label: :repeated}, []), do: <<>>

  defp encode_field(%Field{label: :repeated, type: type}, value) do
    initial_acc = ["]"]

    res =
      value
      |> Enum.reverse()
      |> Enum.reduce(initial_acc, fn v, acc ->
        v_json = encode_value(v, type)

        case acc do
          ^initial_acc -> [v_json | acc]
          _ -> [v_json, "," | acc]
        end
      end)

    ["[" | res]
  end

  defp encode_field(%Field{kind: {:default, default_value}}, value) when value == default_value do
    <<>>
  end

  defp encode_field(%Field{kind: {:default, _default_value}, type: type}, value) do
    encode_value(value, type)
  end

  defp encode_field(%Field{kind: :map}, value) when map_size(value) == 0, do: <<>>

  defp encode_field(%Field{kind: :map, type: {_key_type, value_type}}, value) do
    initial_acc = ["}"]

    res =
      Enum.reduce(value, initial_acc, fn {k, v}, acc ->
        k_json = k |> to_string() |> json_encode()
        v_json = encode_value(v, value_type)

        case acc do
          ^initial_acc -> [k_json, ":", v_json | acc]
          _ -> [k_json, ":", v_json, "," | acc]
        end
      end)

    ["{" | res]
  end

  defp encode_value(value, :bytes), do: "\"#{Base.encode64(value)}\""

  defp encode_value(@positive_infinity_32, :float), do: "\"Infinity\""
  defp encode_value(@negative_infinity_32, :float), do: "\"-Infinity\""
  defp encode_value(@nan_32, :float), do: "\"NaN\""
  defp encode_value(@positive_infinity_64, :double), do: "\"Infinity\""
  defp encode_value(@negative_infinity_64, :double), do: "\"-Infinity\""
  defp encode_value(@nan_64, :double), do: "\"NaN\""

  defp encode_value(value, :int64), do: "\"#{value}\""
  defp encode_value(value, :uint64), do: "\"#{value}\""
  defp encode_value(value, :fixed64), do: "\"#{value}\""
  defp encode_value(value, :sfixed64), do: "\"#{value}\""

  defp encode_value(true, :bool), do: "true"

  defp encode_value(value, {:enum, _enum}) when is_atom(value), do: json_encode(value)
  defp encode_value(value, {:enum, enum}), do: value |> enum.decode() |> json_encode()

  defp encode_value(value, {:message, _}), do: encode!(value)

  defp encode_value(value, _type), do: json_encode(value)

  defp json_encode(value) when is_number(value), do: "#{value}"
  defp json_encode(value), do: "\"#{value}\""
end
