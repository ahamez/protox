defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.FloatValue do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :float))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.FloatValue do
  def encode_message(%Google.Protobuf.FloatValue{} = msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :float, json_encode)
  end
end