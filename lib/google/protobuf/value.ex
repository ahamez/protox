defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.BoolValue do
  def decode_message(initial_message, value) do
    struct!(initial_message, value: value)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.BoolValue do
  def encode_message(%Google.Protobuf.BoolValue{} = msg, json_encode) do
    json_encode.(msg.value)
  end
end
