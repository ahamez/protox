defprotocol Protox.JsonMessageEncoder do
  @moduledoc """
  This protocol enables overriding the JSON encoding of a specific message.
  E.g. it's possible to output Google.Protobuf.Duration as a string rather than
  an object as required by https://developers.google.com/protocol-buffers/docs/proto3#json.
  """

  @fallback_to_any true
  def encode_message(msg, json_encode)
end

defimpl Protox.JsonMessageEncoder, for: Any do
  def encode_message(msg, json_encode) do
    Protox.JsonEncode.encode_message(msg, json_encode)
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Duration do
  def encode_message(msg, _json_encode) do
    "\"#{msg.seconds}\""
  end
end
