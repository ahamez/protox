defmodule Protox.Google.Protobuf.Int32Value do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Int32Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :int32
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Int32Value do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :int32))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Int32Value do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :int32, json_encode)
  end
end
