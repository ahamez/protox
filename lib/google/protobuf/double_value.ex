defmodule Protox.Google.Protobuf.DoubleValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      {
        Google.Protobuf.DoubleValue,
        :proto3,
        [
          Protox.Field.new!(
            kind: {:scalar, 0.0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :double
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.DoubleValue do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :double))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.DoubleValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :double, json_encode)
  end
end
