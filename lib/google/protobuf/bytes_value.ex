defmodule Protox.Google.Protobuf.BytesValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.BytesValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, ""},
            label: :optional,
            name: :value,
            tag: 1,
            type: :bytes
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.BytesValue do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :bytes))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.BytesValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :bytes, json_encode)
  end
end
