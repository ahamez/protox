defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.StringValue do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :string))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.StringValue do
  def encode_message(%Google.Protobuf.StringValue{} = msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :string, json_encode)
  end
end
