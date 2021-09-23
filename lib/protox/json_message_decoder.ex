defprotocol Protox.JsonMessageDecoder do
  @moduledoc """
  This protocol makes possible to override the JSON decoding of a specific message.
  """

  @doc since: "1.6.0"
  @fallback_to_any true
  # @spec decode_message(atom(), struct()) :: struct()
  def decode_message(initial_message, json)
end

defimpl Protox.JsonMessageDecoder, for: Any do
  def decode_message(initial_message, json) do
    Protox.JsonDecode.decode_message(initial_message, json)
  end
end
