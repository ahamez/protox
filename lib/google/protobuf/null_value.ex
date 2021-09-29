# Proto definition
# https://github.com/protocolbuffers/protobuf/blob/master/src/google/protobuf/struct.proto
# JSON encoding
# https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#value

defimpl Protox.JsonEnumDecoder, for: Google.Protobuf.NullValue do
  def decode_enum(_enum, nil), do: :NULL_VALUE
  def decode_enum(_enum, "NULL_VALUE"), do: :NULL_VALUE
  def decode_enum(_enum, _value), do: raise(Protox.JsonDecodingError.new("invalid NullValue"))
end

defimpl Protox.JsonEnumEncoder, for: Google.Protobuf.NullValue do
  def encode_enum(_enum, :NULL_VALUE, json_encode) do
    json_encode.(nil)
  end
end
