defmodule Protox.Google.Protobuf.Timestamp do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      {
        Google.Protobuf.Timestamp,
        :proto3,
        [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :seconds,
            tag: 1,
            type: :int64
          ),
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :nanos,
            tag: 2,
            type: :int32
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Timestamp do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, json) do
    if not String.contains?(json, "T") do
      raise Protox.JsonDecodingError.new("Missing 'T' in timestamp")
    end

    date_time =
      case DateTime.from_iso8601(json) do
        {:ok, dt, _offset} ->
          dt

        _ ->
          raise Protox.JsonDecodingError.new(
                  "invalid timestamp (format or greater than 9999-12-31T23:59:59.999999999Z)"
                )
      end

    unix_timestamp = DateTime.to_unix(date_time, :nanosecond)

    # 0001-01-01T00:00:00Z as UNIX date in nanoseconds
    if unix_timestamp < -62_135_596_800_000_000_000 do
      raise Protox.JsonDecodingError.new("timestamp is < 0001-01-01T00:00:00Z")
    else
      nanos = rem(unix_timestamp, 1_000_000_000)
      seconds = div(unix_timestamp, 1_000_000_000)

      struct!(initial_message, seconds: seconds, nanos: nanos)
    end
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Timestamp do
  def encode_message(msg, json_encode) do
    unix_timestamp = msg.seconds * 1_000_000_000 + msg.nanos

    cond do
      # 9999-12-31T23:59:59.999999999Z as UNIX date in nanoseconds
      unix_timestamp > 253_402_300_799_999_999_000 ->
        raise Protox.JsonEncodingError.new("{msg.__struct__} is > 9999-12-31T23:59:59.999999999Z")

      # 0001-01-01T00:00:00Z as UNIX date in nanoseconds
      unix_timestamp < -62_135_596_800_000_000_000 ->
        raise Protox.JsonEncodingError.new("{msg.__struct__} is < 0001-01-01T00:00:00Z")

      true ->
        unix_timestamp
        |> DateTime.from_unix!(:nanosecond)
        |> DateTime.to_iso8601()
        |> json_encode.()
    end
  end
end
