defmodule Protox.Google.Protobuf.StringValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.StringValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, ""},
            label: :optional,
            name: :value,
            tag: 1,
            type: :string
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.StringValue do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :string))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.StringValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :string, json_encode)
  end
end
