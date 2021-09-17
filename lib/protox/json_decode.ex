defmodule Protox.JsonDecode do
  @moduledoc false

  alias Protox.Field

  # @spec decode!(atom(), iodata(), fun()) :: struct() | no_return()
  def decode!(input, mod, json_decode) do
    json = json_decode.(input)

    Protox.JsonMessageDecoder.decode_message(mod, json)
  end

  def decode_message(mod, json) do
    initial_msg = struct!(mod)

    Enum.reduce(json, initial_msg, fn {field_json_name, field_value}, acc ->
      field = get_field(mod, field_json_name)
      field_value = decode_msg_field(field, field_value)

      Map.put(acc, field.name, field_value)
    end)
  end

  # -- Private

  defp decode_msg_field(%Field{kind: {:default, default_value}}, nil = _json_value) do
    default_value
  end

  defp decode_msg_field(%Field{kind: {:default, _default_value}} = field, json_value) do
    decode_value(json_value, field.type)
  end

  defp decode_msg_field(%Field{} = _field, _json_value) do
    raise "TODO"
  end

  defp decode_value(json_value, _type), do: json_value

  defp get_field(mod, json_name) do
    case mod.field_def(json_name) do
      {:ok, %Field{} = field} ->
        field

      {:error, :no_such_field} ->
        raise Protox.JsonDecodingError.new(mod, "#{json_name} is not a field of #{mod}")
    end
  end
end
