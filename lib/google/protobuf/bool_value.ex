defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.BoolValue do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: value)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.BoolValue do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :bool, json_encode)
  end
end
