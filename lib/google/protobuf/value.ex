# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto
# JSON encoding
# https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#value

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

  def decode_message(_initial_message, _value) do
    raise Protox.JsonDecodingError.new("invalid Value format")
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
end
