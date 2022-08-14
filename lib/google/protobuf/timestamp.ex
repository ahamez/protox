defmodule Protox.Google.Protobuf.Timestamp do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Timestamp,
        syntax: :proto3,
        fields: [
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

  def max_timestamp_rfc(), do: "9999-12-31T23:59:59.999999999Z"
  def max_timestamp_nanos(), do: 253_402_300_799_999_999_999

  def min_timestamp_rfc(), do: "0001-01-01T00:00:00Z"
  def min_timestamp_nanos(), do: -62_135_596_800_000_000_000
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Timestamp do
  alias Protox.Google.Protobuf.Timestamp

  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, json) do
    if not String.contains?(json, "T") do
      raise Protox.JsonDecodingError.new("Missing 'T' in timestamp")
    end

    # We only use DateTime to validate format as it does correctly parse timestamps
    # with nanosecond precision, but the result has only a microsecond precision.
    # It would have been preferable to use only :calendar.rfc3339_to_system_time,
    # but it's too lax as it accepts 'z' (which should be uppercase)
    # which is not accepted by the conformance tests.
    if match?({:error, _}, DateTime.from_iso8601(json)) do
      raise Protox.JsonDecodingError.new("Invalid timestamp format")
    end

    unix_timestamp =
      json
      |> String.to_charlist()
      |> :calendar.rfc3339_to_system_time([{:unit, :nanosecond}])

    if unix_timestamp < Timestamp.min_timestamp_nanos() do
      raise Protox.JsonDecodingError.new("Timestamp < #{Timestamp.min_timestamp_rfc()}")
    else
      nanos = rem(unix_timestamp, 1_000_000_000)
      seconds = div(unix_timestamp, 1_000_000_000)

      struct!(initial_message, seconds: seconds, nanos: nanos)
    end
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Timestamp do
  alias Protox.Google.Protobuf.Timestamp

  def encode_message(msg, json_encode) do
    unix_timestamp = msg.seconds * 1_000_000_000 + msg.nanos

    cond do
      unix_timestamp > Timestamp.max_timestamp_nanos() ->
        raise Protox.JsonEncodingError.new("#{msg.__struct__} > #{Timestamp.max_timestamp_rfc()}")

      unix_timestamp < Timestamp.min_timestamp_nanos() ->
        raise Protox.JsonEncodingError.new("#{msg.__struct__} < #{Timestamp.min_timestamp_rfc()}")

      true ->
        # Conformance tests recommend to remove useless fractional part.
        suffix_to_remove =
          cond do
            rem(msg.nanos, 1_000_000_000) == 0 -> ".000000000Z"
            rem(msg.nanos, 1_000_000) == 0 -> "000000Z"
            rem(msg.nanos, 1_000) == 0 -> "000Z"
            true -> "Z"
          end

        unix_timestamp
        |> :calendar.system_time_to_rfc3339([{:unit, :nanosecond}, {:offset, 'Z'}])
        |> List.to_string()
        |> String.replace_trailing(suffix_to_remove, "Z")
        |> json_encode.()
    end
  end
end
