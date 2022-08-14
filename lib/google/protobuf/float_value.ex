defmodule Protox.Google.Protobuf.FloatValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.FloatValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0.0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :float
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.FloatValue do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :float))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.FloatValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :float, json_encode)
  end
end
