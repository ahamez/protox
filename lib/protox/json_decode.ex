defmodule Protox.JsonDecode do
  @moduledoc false

  alias Protox.{Field, JsonDecodingError, JsonEnumDecoder, JsonMessageDecoder}

  import Protox.Guards

  use Protox.{Float, Integer}

  @spec decode!(iodata(), atom(), fun()) :: struct() | no_return()
  def decode!(input, mod, json_decode) do
    case json_decode.(input) do
      nil -> raise JsonDecodingError.new("invalid top-level null")
      json -> JsonMessageDecoder.decode_message(struct(mod), json)
    end
  end

  def decode_message(_initial_msg, nil), do: nil

  def decode_message(initial_msg, json) when is_map(json) do
    Enum.reduce(json, initial_msg, fn {field_json_name, field_value}, msg_acc ->
      case get_field(initial_msg, field_json_name) do
        {:ok, field} ->
          case decode_msg_field(field, field_value, msg_acc) do
            nil ->
              msg_acc

            {_field_name, nil} ->
              msg_acc

            {field_name, field_value} ->
              Map.put(msg_acc, field_name, field_value)
          end

        {:error, :no_such_field} ->
          msg_acc
      end
    end)
  end

  def decode_message(_initial_msg, _json) do
    raise JsonDecodingError.new("Expected an object for message field")
  end

  def decode_enum(_enum, nil), do: nil

  def decode_enum(enum, json) when is_integer(json) do
    enum.__struct__.decode(json)
  end

  def decode_enum(enum, json) when is_binary(json) do
    if enum.__struct__.encode(json) == json do
      # It's quite a hack: generated encode/1 returns its argument unmodified if it's not
      # part of the enum.
      raise JsonDecodingError.new("#{json} is not value of #{enum.__struct__}")
    else
      String.to_atom(json)
    end
  end

  def decode_value("Infinity", type) when is_protobuf_float(type), do: :infinity
  def decode_value("-Infinity", type) when is_protobuf_float(type), do: :"-infinity"
  def decode_value("NaN", type) when is_protobuf_float(type), do: :nan

  def decode_value(true, :bool), do: true
  def decode_value(false, :bool), do: false

  def decode_value(json_value, type) when is_binary(json_value) and is_protobuf_float(type) do
    case Float.parse(json_value) do
      {value, ""} -> decode_value(value, type)
      _ -> raise JsonDecodingError.new("#{json_value} is not a valid float")
    end
  end

  def decode_value(json_value, type) when is_binary(json_value) and is_primitive(type) do
    case Integer.parse(json_value) do
      {value, ""} -> decode_value(value, type)
      _ -> raise JsonDecodingError.new("#{json_value} is not a valid integer")
    end
  end

  def decode_value(json_value, :bytes) when is_binary(json_value) do
    try do
      Base.url_decode64!(json_value, padding: false)
    rescue
      e in ArgumentError ->
        reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end

  def decode_value(json_value, :string) when is_binary(json_value), do: json_value

  def decode_value(json_value, {:enum, enum_mod}) do
    JsonEnumDecoder.decode_enum(struct(enum_mod), json_value)
  end

  def decode_value(json_value, {:message, msg_mod}) do
    JsonMessageDecoder.decode_message(struct(msg_mod), json_value)
  end

  def decode_value(json_value, type)
      when type in [:uint32, :fixed32] and is_integer(json_value) and
             json_value > @max_unsigned_32 do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:int32, :sint32, :sfixed32] and is_integer(json_value) and
             json_value > @max_signed_32 do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:int32, :sint32, :sfixed32] and is_integer(json_value) and
             json_value < @min_signed_32 do
    raise JsonDecodingError.new("#{json_value} is too small for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:uint64, :fixed64] and is_integer(json_value) and
             json_value > @max_unsigned_64 do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:int64, :sint64, :sfixed64] and is_integer(json_value) and
             json_value > @max_signed_64 do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:int64, :sint64, :sfixed64] and is_integer(json_value) and
             json_value < @min_signed_64 do
    raise JsonDecodingError.new("#{json_value} is too small for a #{type}")
  end

  def decode_value(json_value, type)
      when type in [:uint32, :fixed32, :uint64, :fixed64] and is_integer(json_value) and
             json_value < 0 do
    raise JsonDecodingError.new("#{json_value} is too small for a #{type}")
  end

  def decode_value(json_value, type)
      when type == :float and is_number(json_value) and json_value > @max_float do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type == :float and is_number(json_value) and json_value < @min_float do
    raise JsonDecodingError.new("#{json_value} is too small for a #{type}")
  end

  def decode_value(json_value, type)
      when type == :double and is_number(json_value) and json_value > @max_double do
    raise JsonDecodingError.new("#{json_value} is too large for a #{type}")
  end

  def decode_value(json_value, type)
      when type == :double and is_number(json_value) and json_value < @min_double do
    raise JsonDecodingError.new("#{json_value} is too small for a #{type}")
  end

  def decode_value(json_value, type) when is_protobuf_integer(type) and is_float(json_value) do
    decimal_float = Decimal.from_float(json_value)

    if Decimal.equal?(Decimal.round(decimal_float), decimal_float) do
      decode_value(Decimal.to_integer(decimal_float), type)
    else
      raise JsonDecodingError.new(
              "cannot decode #{inspect(json_value)} for type #{inspect(type)}"
            )
    end
  end

  def decode_value(json_value, type) when is_protobuf_integer(type) and is_integer(json_value) do
    json_value
  end

  def decode_value(json_value, type) when is_protobuf_float(type) and is_number(json_value) do
    json_value
  end

  def decode_value(nil = _json_value, type)
      when is_primitive(type) or type == :bytes or type == :string do
    nil
  end

  def decode_value(json_value, type) do
    raise JsonDecodingError.new("cannot decode #{inspect(json_value)} for type #{inspect(type)}")
  end

  # -- Private

  defp decode_msg_field(%Field{kind: {:scalar, _default_value}} = field, json_value, _msg) do
    {field.name, decode_value(json_value, field.type)}
  end

  defp decode_msg_field(%Field{label: :proto3_optional} = field, json_value, _msg) do
    field_value = decode_value(json_value, field.type)

    case field_value do
      nil -> nil
      field_value -> {field.name, field_value}
    end
  end

  defp decode_msg_field(%Field{kind: {:oneof, parent_name}} = field, json_value, msg) do
    field_value = decode_value(json_value, field.type)

    if Map.fetch!(msg, parent_name) != nil and field_value != nil do
      raise JsonDecodingError.new("oneof #{parent_name} already set")
    else
      case field_value do
        nil -> nil
        field_value -> {parent_name, {field.name, field_value}}
      end
    end
  end

  defp decode_msg_field(%Field{kind: :map} = _field, nil = _json_value, _msg), do: nil

  defp decode_msg_field(
         %Field{kind: :map, type: {key_type, value_type}} = field,
         json_value,
         _msg
       )
       when is_map(json_value) do
    map =
      json_value
      |> Stream.map(fn
        {_key, nil} ->
          raise JsonDecodingError.new("found null value in map")

        # A special case for booleans is required as they are accepted as strings
        # when keys of a map, but not as values (which means we can't have a
        # decode_value() function for :bool
        {"true", value} when key_type == :bool ->
          {true, decode_value(value, value_type)}

        {"false", value} when key_type == :bool ->
          {false, decode_value(value, value_type)}

        {key, value} ->
          {decode_value(key, key_type), decode_value(value, value_type)}
      end)
      |> Enum.into(%{})

    {field.name, map}
  end

  defp decode_msg_field(%Field{kind: :map} = field, _json_value, _msg) do
    raise JsonDecodingError.new("Expected a map for field #{field.name}")
  end

  defp decode_msg_field(%Field{label: :repeated} = _field, nil = _json_value, _msg), do: nil

  defp decode_msg_field(%Field{label: :repeated} = field, json_value, _msg)
       when is_list(json_value) do
    list =
      Enum.map(json_value, fn value ->
        case decode_value(value, field.type) do
          nil -> raise JsonDecodingError.new("found null value in array")
          decoded_value -> decoded_value
        end
      end)

    {field.name, list}
  end

  defp decode_msg_field(%Field{label: :repeated} = field, _json_value, _msg) do
    raise JsonDecodingError.new("Expected a list for field #{field.name}")
  end

  defp get_field(msg, json_name) do
    msg.__struct__.field_def(json_name)
  end
end
