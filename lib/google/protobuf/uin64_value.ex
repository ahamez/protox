defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.UInt64Value do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :uint64))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.UInt64Value do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :uint64, json_encode)
  end
end
