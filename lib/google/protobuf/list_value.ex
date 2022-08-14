# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto
# JSON encoding
# https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#listvalue

defmodule Protox.Google.Protobuf.ListValue do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.ListValue,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: :unpacked,
            label: :repeated,
            name: :values,
            tag: 1,
            type: {:message, Google.Protobuf.Value}
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.ListValue do
  def decode_message(initial_message, value) when is_list(value) do
    values =
      Enum.map(value, fn entry ->
        Protox.JsonMessageDecoder.decode_message(%Google.Protobuf.Value{}, entry)
      end)

    struct!(initial_message, values: values)
  end

  def decode_message(_initial_message, _value) do
    raise Protox.JsonDecodingError.new("invalid ListValue")
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.ListValue do
  def encode_message(%Google.Protobuf.ListValue{} = msg, json_encode) do
    json_list =
      msg.values
      |> Stream.map(&Protox.JsonMessageEncoder.encode_message(&1, json_encode))
      |> Enum.join(",")

    ["[", json_list, "]"]
  end
end
