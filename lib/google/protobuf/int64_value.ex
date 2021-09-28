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
