# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto
# JSON encoding
# https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#struct

defmodule Protox.Google.Protobuf.Struct do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Struct,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: :map,
            label: nil,
            name: :fields,
            tag: 1,
            type: {:string, {:message, Google.Protobuf.Value}}
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Struct do
  def decode_message(initial_message, value) when is_map(value) do
    fields =
      value
      |> Stream.map(fn {key, value} when is_binary(key) ->
        {key, Protox.JsonMessageDecoder.decode_message(%Google.Protobuf.Value{}, value)}
      end)
      |> Enum.into(%{})

    struct!(initial_message, fields: fields)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Struct do
  def encode_message(%Google.Protobuf.Struct{} = msg, json_encode) do
    json_map =
      msg.fields
      |> Stream.map(fn {key, value} ->
        encoded_value = Protox.JsonMessageEncoder.encode_message(value, json_encode)
        "\"#{key}\": #{encoded_value}"
      end)
      |> Enum.join(",")

    ["{", json_map, "}"]
  end
end
