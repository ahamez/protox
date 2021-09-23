defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Int32Value do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :int32))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Int32Value do
  def encode_message(%Google.Protobuf.Int32Value{} = msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :int32, json_encode)
  end
end
