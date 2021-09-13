defmodule Protox.JsonEncode do
  @doc """
  TODO
  """

  alias Protox.Field

  use Protox.Float

  @spec encode!(struct()) :: iodata()
  def encode!(msg, json_encoder \\ Jason) do
    initial_acc = ["}"]

    body =
      msg.__struct__.fields()
      |> Enum.reduce(initial_acc, fn %Field{} = field, acc ->
        case encode_msg_field(msg, field, json_encoder) do
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

  defp encode_msg_field(_msg, %Field{kind: {:oneof, _parent}}, _json_encoder) do
    <<>>
  end

  defp encode_msg_field(msg, %Field{} = field, json_encoder) do
    field_value = Map.fetch!(msg, field.name)
    json_value = encode_field(field, field_value, json_encoder)

    case json_value do
      <<>> -> <<>>
      _ -> [json_encoder.encode!(field.json_name), ":", json_value]
    end
  end

  defp encode_field(%Field{kind: {:default, default_value}}, value, _json_encoder)
       when value == default_value do
    <<>>
  end

  defp encode_field(%Field{kind: {:default, _default_value}, type: type}, value, json_encoder) do
    encode_value(value, type, json_encoder)
  end

  defp encode_field(%Field{kind: :map}, value, _json_encoder) when map_size(value) == 0 do
    <<>>
  end

  defp encode_field(%Field{kind: :map, type: {_key_type, value_type}}, value, json_encoder) do
    initial_acc = ["}"]

    res =
      Enum.reduce(value, initial_acc, fn {k, v}, acc ->
        k_json = k |> to_string() |> json_encoder.encode!()
        v_json = encode_value(v, value_type, json_encoder)

        case acc do
          ^initial_acc -> [k_json, ":", v_json | acc]
          _ -> [k_json, ":", v_json, "," | acc]
        end
      end)

    ["{" | res]
  end

  defp encode_field(_field, _type, _json_encoder) do
    <<>>
  end

  defp encode_value(value, {:enum, enum}, json_encoder) when is_integer(value) do
    value |> enum.decode() |> json_encoder.encode!()
  end

  defp encode_value(value, {:enum, _enum}, json_encoder) when is_atom(value) do
    json_encoder.encode!(value)
  end

  defp encode_value(value, :bytes, json_encoder) do
    value |> Base.encode64() |> json_encoder.encode!()
  end

  defp encode_value(@positive_infinity_32, :float, _json_encoder), do: "\"Infinity\""
  defp encode_value(@negative_infinity_32, :float, _json_encoder), do: "\"-Infinity\""
  defp encode_value(@nan_32, :float, _json_encoder), do: "\"NaN\""
  defp encode_value(@positive_infinity_64, :double, _json_encoder), do: "\"Infinity\""
  defp encode_value(@negative_infinity_64, :double, _json_encoder), do: "\"-Infinity\""
  defp encode_value(@nan_64, :double, _json_encoder), do: "\"NaN\""
  defp encode_value(true, :bool, _json_encoder), do: "true"
  defp encode_value(value, {:message, _}, json_encoder), do: encode!(value, json_encoder)
  defp encode_value(value, _type, json_encoder), do: json_encoder.encode!(value)
end
