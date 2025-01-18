defmodule Protox.Google.Protobuf.Timestamp do
  @moduledoc false

  use Protox.Define,
    enums: %{},
    messages: %{
      Google.Protobuf.Timestamp => %Protox.Message{
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
    }

  def max_timestamp_rfc(), do: "9999-12-31T23:59:59.999999999Z"
  def max_timestamp_nanos(), do: 253_402_300_799_999_999_999

  def min_timestamp_rfc(), do: "0001-01-01T00:00:00Z"
  def min_timestamp_nanos(), do: -62_135_596_800_000_000_000
end
