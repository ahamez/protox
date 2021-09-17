defprotocol Protox.JsonMessageEncoder do
  @moduledoc """
  This protocol makes possible to override the JSON encoding of a specific message.

  For instance, it's possible to encode
  [Google.Protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)
  as a string rather than
  an object as required by the [JSON encoding specification](https://developers.google.com/protocol-buffers/docs/proto3#json).
  """

  @doc """
  The contract of a message encoder.

  - `msg` is the protobuf message to encode
  - `json_encode` is the function to use in the protocol implementation to encode values to JSON
  """
  @doc since: "1.6.0"
  @fallback_to_any true
  @spec encode_message(struct(), (any() -> iodata())) :: iodata()
  def encode_message(msg, json_encode)
end

defimpl Protox.JsonMessageEncoder, for: Any do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_message(msg, json_encode)
  end
end
