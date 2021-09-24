defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.DoubleValue do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :double))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.DoubleValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :double, json_encode)
  end
end
