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
      <<>> ->
        <<>>

      _ ->
        json_name =
          field.name
          |> Atom.to_string()
          |> lower_camel_case()
          |> json_encoder.encode!()

        [json_name, ":", json_value]
    end
  end

  defp encode_field(%Field{kind: {:default, _}, type: {:message, _msg}}, nil, _json_encoder) do
    <<>>
  end

  defp encode_field(
         %Field{kind: {:default, _default_value}, type: {:message, _msg}},
         value,
         json_encoder
       ) do
    encode!(value, json_encoder)
  end

  defp encode_field(
         %Field{kind: {:default, default_value}, type: {:enum, _enum}},
         value,
         _json_encoder
       )
       when value == default_value do
    <<>>
  end

  defp encode_field(
         %Field{kind: {:default, _default_value}, type: {:enum, enum}},
         value,
         json_encoder
       )
       when is_integer(value) do
    value |> enum.decode() |> json_encoder.encode!()
  end

  defp encode_field(
         %Field{kind: {:default, _default_value}, type: {:enum, _enum}},
         value,
         json_encoder
       )
       when is_atom(value) do
    json_encoder.encode!(value)
  end

  defp encode_field(%Field{kind: {:default, _default_value}, type: :bytes}, <<>>, _json_encoder) do
    <<>>
  end

  defp encode_field(%Field{kind: {:default, _default_value}, type: :bytes}, value, json_encoder) do
    value |> Base.encode64() |> json_encoder.encode!()
  end

  defp encode_field(%Field{kind: {:default, default_value}}, value, _json_encoder)
       when value == default_value do
    <<>>
  end

  defp encode_field(%Field{type: :float}, @positive_infinity_32, _json_encoder) do
    "\"Infinity\""
  end

  defp encode_field(%Field{type: :float}, @negative_infinity_32, _json_encoder) do
    "\"-Infinity\""
  end

  defp encode_field(%Field{type: :float}, @nan_32, _json_encoder) do
    "\"NaN\""
  end

  defp encode_field(%Field{type: :double}, @positive_infinity_64, _json_encoder) do
    "\"Infinity\""
  end

  defp encode_field(%Field{type: :double}, @negative_infinity_64, _json_encoder) do
    "\"-Infinity\""
  end

  defp encode_field(%Field{type: :double}, @nan_64, _json_encoder) do
    "\"NaN\""
  end

  defp encode_field(%Field{kind: {:default, _default_value}}, value, json_encoder) do
    json_encoder.encode!(value)
  end

  defp encode_field(_field, _type, _json_encoder) do
    <<>>
  end

  defp lower_camel_case(string) do
    <<first, rest::binary>> = Macro.camelize(string)

    <<String.downcase(<<first>>, :ascii)::binary, rest::binary>>
  end
end
