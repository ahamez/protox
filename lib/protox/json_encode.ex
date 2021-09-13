defmodule Protox.JsonEncode do
  @doc """
  TODO
  """

  use Protox.Float

  @spec encode(struct()) :: iodata()
  def encode(msg, json_encoder \\ Jason) do
    initial_acc = ["}"]

    body =
      msg.__struct__.defs()
      |> Map.to_list()
      |> Enum.reduce(initial_acc, fn field, acc ->
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

  defp encode_msg_field(_msg, {_tag, {_name, {:oneof, _parent}, _type}}, _json_encoder) do
    <<>>
  end

  defp encode_msg_field(msg, {_tag, {name, kind, type}}, json_encoder) do
    field_value = Map.fetch!(msg, name)
    json_value = encode_field(field_value, kind, type, json_encoder)

    case json_value do
      <<>> ->
        <<>>

      _ ->
        json_name =
          name
          |> Atom.to_string()
          |> lower_camel_case()
          |> json_encoder.encode!()

        [json_name, ":", json_value]
    end
  end

  defp encode_field(nil, {:default, _}, {:message, _msg_type}, _json_encoder) do
    <<>>
  end

  defp encode_field(value, {:default, _default_value}, {:message, _msg_type}, json_encoder) do
    encode(value, json_encoder)
  end

  defp encode_field(value, {:default, default_value}, {:enum, _msg_type}, _json_encoder)
       when value == default_value do
    <<>>
  end

  defp encode_field(value, {:default, _default_value}, {:enum, enum_type}, json_encoder)
       when is_integer(value) do
    value |> enum_type.decode() |> json_encoder.encode!()
  end

  defp encode_field(value, {:default, _default_value}, {:enum, _msg_type}, json_encoder)
       when is_atom(value) do
    json_encoder.encode!(value)
  end

  defp encode_field(<<>>, {:default, _default_value}, :bytes, _json_encoder) do
    <<>>
  end

  defp encode_field(value, {:default, _default_value}, :bytes, json_encoder) do
    value |> Base.encode64() |> json_encoder.encode!()
  end

  defp encode_field(value, {:default, default_value}, _type, _json_encoder)
       when value == default_value do
    <<>>
  end

  defp encode_field(@positive_infinity_32, _kind, :float, _json_encoder), do: "Infinity"
  defp encode_field(@negative_infinity_32, _kind, :float, _json_encoder), do: "-Infinity"
  defp encode_field(@nan_32, _kind, :float, _json_encoder), do: "NaN"
  defp encode_field(@positive_infinity_64, _kind, :double, _json_encoder), do: "Infinity"
  defp encode_field(@negative_infinity_64, _kind, :double, _json_encoder), do: "-Infinity"
  defp encode_field(@nan_64, _kind, :double, _json_encoder), do: "NaN"

  defp encode_field(value, {:default, _default_value}, _type, json_encoder) do
    json_encoder.encode!(value)
  end

  defp encode_field(_value, _kind, _type, _json_encoder) do
    <<>>
  end

  defp lower_camel_case(string) do
    <<first, rest::binary>> = Macro.camelize(string)

    <<String.downcase(<<first>>, :ascii)::binary, rest::binary>>
  end
end
