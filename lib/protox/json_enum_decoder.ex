defprotocol Protox.JsonEnumDecoder do
  @moduledoc false

  @doc since: "1.6.0"
  @fallback_to_any true
  @spec decode_enum(struct(), binary()) :: any()
  def decode_enum(enum, json)
end

defimpl Protox.JsonEnumDecoder, for: Any do
  def decode_enum(enum, json) do
    Protox.JsonDecode.decode_enum(enum, json)
  end
end
