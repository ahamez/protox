defmodule Protox.Google.Protobuf.Int64Value do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Int64Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :value,
            tag: 1,
            type: :int64
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Int64Value do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :int64))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Int64Value do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :int64, json_encode)
  end
end
