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
  def encode_message(msg, _json_encode) do
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
        duration = msg.seconds + msg.nanos / 1_000_000_000
        "\"#{Float.round(duration, 6)}s\""
    end
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Timestamp do
  def encode_message(msg, _json_encode) do
    unix_timestamp = msg.seconds * 1_000_000_000 + msg.nanos

    cond do
      unix_timestamp > 253_402_300_799 * 1_000_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "timestamp is > 9999-12-31T23:59:59.999999999Z")

      unix_timestamp < -62_135_596_800 * 1_000_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "timestamp is < 0001-01-01T00:00:00Z")

      true ->
        unix_timestamp
        |> DateTime.from_unix!(:nanosecond)
        |> DateTime.to_iso8601()
    end
  end
end
