defmodule Protox.JsonDecode do
  @moduledoc false

  alias Protox.{Field, JsonDecodingError, JsonMessageDecoder}

  # @spec decode!(iodata(), atom(), fun()) :: struct() | no_return()
  def decode!(input, mod, json_decode) do
    json = json_decode.(input)

    JsonMessageDecoder.decode_message(mod, json)
  end

  def decode_message(mod, json) do
    initial_msg = struct!(mod)

    Enum.reduce(json, initial_msg, fn {field_json_name, field_value}, acc ->
      field = get_field(mod, field_json_name)
      {field_name, field_value} = decode_msg_field(field, field_value)

      Map.put(acc, field_name, field_value)
    end)
  end

  # -- Private

  defp decode_msg_field(%Field{kind: {:default, default_value}} = field, nil = _json_value) do
    {field.name, default_value}
  end

  defp decode_msg_field(%Field{kind: {:default, _default_value}} = field, json_value) do
    {field.name, decode_value(json_value, field.type)}
  end

  defp decode_msg_field(%Field{kind: {:oneof, parent_name}} = field, json_value) do
    {parent_name, {field.name, decode_value(json_value, field.type)}}
  end

  defp decode_msg_field(%Field{} = _field, _json_value) do
    raise "TODO"
  end

  defp decode_value(json_value, type)
       when is_binary(json_value) and type in [:int64, :fixed64, :sfixed64, :uint64] do
    case Integer.parse(json_value) do
      {value, ""} -> value
      _ -> raise JsonDecodingError.new("#{json_value} is not a valid integer")
    end
  end

  defp decode_value("Infinity", type) when type in [:double, :float], do: :infinity
  defp decode_value("-Infinity", type) when type in [:double, :float], do: :"-infinity"
  defp decode_value("NaN", type) when type in [:double, :float], do: :nan

  defp decode_value(json_value, type) when is_binary(json_value) and type in [:double, :float] do
    case Float.parse(json_value) do
      {value, ""} -> value
      _ -> raise JsonDecodingError.new("#{json_value} is not a valid float")
    end
  end

  defp decode_value(json_value, :bytes = _type), do: Base.decode64!(json_value)

  defp decode_value(json_value, {:enum, enum_mod} = _type) when is_integer(json_value) do
    enum_mod.decode(json_value)
  end

  defp decode_value(json_value, {:enum, enum_mod} = _type) when is_binary(json_value) do
    try do
      as_atom = String.to_existing_atom(json_value)

      if is_atom(enum_mod.encode(as_atom)) do
        # It's quite a hack: as the generated encode/1 of an enum does not indicate
        # if the given atom has been correctly encoded as a number, we check the type
        # of the returned value to detect if `as_atom` is part of the enum.
        raise JsonDecodingError.new("#{json_value} is not a field of #{enum_mod}")
      else
        as_atom
      end
    rescue
      ArgumentError ->
        reraise JsonDecodingError.new("#{json_value} is not a field of #{enum_mod}"),
                __STACKTRACE__
    end
  end

  defp decode_value(json_value, {:message, msg_mod}) do
    JsonMessageDecoder.decode_message(msg_mod, json_value)
  end

  defp decode_value(json_value, _type), do: json_value

  defp get_field(mod, json_name) do
    case mod.field_def(json_name) do
      {:ok, %Field{} = field} ->
        field

      {:error, :no_such_field} ->
        raise JsonDecodingError.new("#{json_name} is not a field of #{mod}")
    end
  end
end
