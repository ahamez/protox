defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Timestamp do
  def decode_message(initial_message, json) do
    {:ok, dt, _offset} = DateTime.from_iso8601(json)
    unix_timestamp = DateTime.to_unix(dt, :nanosecond)

    nanos = rem(unix_timestamp, 1_000_000_000)
    seconds = div(unix_timestamp, 1_000_000_000)

    struct!(initial_message, seconds: seconds, nanos: nanos)
  end

  # -- Private
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Timestamp do
  def encode_message(msg, json_encode) do
    unix_timestamp = msg.seconds * 1_000_000_000 + msg.nanos

    cond do
      # 9999-12-31T23:59:59.999999999Z as UNIX date in nanoseconds
      unix_timestamp > 253_402_300_799_999_999_000 ->
        raise Protox.JsonEncodingError.new(msg, "timestamp is > 9999-12-31T23:59:59.999999999Z")

      # 0001-01-01T00:00:00Z as UNIX date in nanoseconds
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
