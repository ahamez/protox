defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.UInt32Value do
  def decode_message(_initial_message, nil), do: nil

  def decode_message(initial_message, value) do
    struct!(initial_message, value: Protox.JsonDecode.decode_value(value, :uint32))
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.UInt32Value do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_value(msg.value, :uint32, json_encode)
  end
end
