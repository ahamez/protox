# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto
# JSON encoding
# https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#value

defmodule Protox.Google.Protobuf.Value do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Value,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :null_value,
            tag: 1,
            type: {:enum, Google.Protobuf.NullValue}
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :number_value,
            tag: 2,
            type: :double
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :string_value,
            tag: 3,
            type: :string
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :bool_value,
            tag: 4,
            type: :bool
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :struct_value,
            tag: 5,
            type: {:message, Google.Protobuf.Struct}
          ),
          Protox.Field.new!(
            kind: {:oneof, :kind},
            label: :optional,
            name: :list_value,
            tag: 6,
            type: {:message, Google.Protobuf.ListValue}
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Value do
  def decode_message(initial_message, value) when is_boolean(value) do
    struct!(initial_message, kind: {:bool_value, value})
  end

  def decode_message(initial_message, nil = _value) do
    struct!(initial_message, kind: {:null_value, :NULL_VALUE})
  end

  def decode_message(initial_message, value) when is_binary(value) do
    struct!(initial_message, kind: {:string_value, value})
  end

  def decode_message(initial_message, value) when is_number(value) do
    struct!(initial_message, kind: {:number_value, value})
  end

  def decode_message(initial_message, value) when is_list(value) do
    list_value = Protox.JsonMessageDecoder.decode_message(%Google.Protobuf.ListValue{}, value)

    struct!(initial_message, kind: {:list_value, list_value})
  end

  def decode_message(initial_message, value) when is_map(value) do
    struct_value = Protox.JsonMessageDecoder.decode_message(%Google.Protobuf.Struct{}, value)

    struct!(initial_message, kind: {:struct_value, struct_value})
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Value do
  def encode_message(%Google.Protobuf.Value{kind: {kind, value}}, json_encode)
      when kind in [:bool_value, :string_value, :number_value] do
    json_encode.(value)
  end

  def encode_message(%Google.Protobuf.Value{kind: {:null_value, :NULL_VALUE}}, json_encode) do
    json_encode.(nil)
  end

  def encode_message(
        %Google.Protobuf.Value{kind: {:list_value, %Google.Protobuf.ListValue{} = list_value}},
        json_encode
      ) do
    Protox.JsonMessageEncoder.encode_message(list_value, json_encode)
  end

  def encode_message(
        %Google.Protobuf.Value{kind: {:struct_value, %Google.Protobuf.Struct{} = struct_value}},
        json_encode
      ) do
    Protox.JsonMessageEncoder.encode_message(struct_value, json_encode)
  end

  def encode_message(%Google.Protobuf.Value{kind: _}, _json_encode) do
    raise Protox.JsonEncodingError.new("invalid field :kind for Value")
  end
end
