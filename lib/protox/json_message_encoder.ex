defprotocol Protox.JsonMessageEncoder do
  @moduledoc """
  This protocol enables overriding the JSON encoding of a specific message.
  E.g. it's possible to output Google.Protobuf.Duration as a string rather than
  an object as required by https://developers.google.com/protocol-buffers/docs/proto3#json.
  """

  @fallback_to_any true
  def encode_message(msg, json_encode)
end

defimpl Protox.JsonMessageEncoder, for: Any do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_message(msg, json_encode)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Duration do
  def encode_message(msg, json_encode) do
    cond do
      msg.seconds < -315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "seconds is < -315_576_000_000")

      msg.seconds > 315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "seconds is > 315_576_000_000")

      msg.nanos < -999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "nanos is < -999_999_999")

      msg.nanos > 999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "nanos is > 999_999_999")

      true ->
        duration =
          Decimal.add(
            Decimal.new(msg.seconds),
            Decimal.div(Decimal.new(msg.nanos), Decimal.new(1_000_000_000))
          )

        json_encode.("#{Decimal.round(duration, 6)}s")
    end
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Timestamp do
  def encode_message(msg, json_encode) do
    unix_timestamp = msg.seconds * 1_000_000_000 + msg.nanos

    cond do
      unix_timestamp > 253_402_300_799_999_999_000 ->
        raise Protox.JsonEncodingError.new(msg, "timestamp is > 9999-12-31T23:59:59.999999999Z")

      unix_timestamp < -62_135_596_800_000_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "timestamp is < 0001-01-01T00:00:00Z")

      true ->
        unix_timestamp
        |> DateTime.from_unix!(:nanosecond)
        |> DateTime.to_iso8601()
        |> json_encode.()
    end
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.FieldMask do
  def encode_message(msg, json_encode) do
    case check_paths(msg.paths) do
      :ok ->
        msg.paths
        |> Enum.map(&lower_camel_case/1)
        |> Enum.join(",")
        |> json_encode.()

      :error ->
        raise Protox.JsonEncodingError.new(msg, "path is invalid")
    end
  end

  defp lower_camel_case(string) do
    string
    |> String.split(".")
    |> Enum.map(fn str ->
      <<first, rest::binary>> = Macro.camelize(str)

      <<String.downcase(<<first>>, :ascii)::binary, rest::binary>>
    end)
    |> Enum.join(".")
  end

  defp check_paths(paths) do
    res =
      Enum.any?(paths, fn path ->
        with false <- has_too_many_underscores?(path),
             false <- has_a_number_in_path_component?(path),
             false <- has_camel_cased_components?(path) do
          false
        else
          _ ->
            true
        end
      end)

    if res do
      :error
    else
      :ok
    end
  end

  defp has_too_many_underscores?(path) do
    String.contains?(path, "__")
  end

  defp has_a_number_in_path_component?(path) do
    path
    |> String.split("_")
    |> Enum.any?(fn str ->
      String.starts_with?(str, ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    end)
  end

  defp has_camel_cased_components?(path) do
    path
    |> String.split("_")
    |> Enum.any?(fn str -> str == lower_camel_case(str) and not (str == String.downcase(str)) end)
  end
end
