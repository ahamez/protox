defprotocol Protox.JsonEnumEncoder do
  @moduledoc false

  @doc since: "1.6.0"
  @fallback_to_any true
  @spec encode_enum(struct(), any(), (any() -> iodata())) :: iodata()
  def encode_enum(enum, value, json_encode)
end

defimpl Protox.JsonEnumEncoder, for: Any do
  def encode_enum(enum, value, json_encode) do
    Protox.JsonEncode.encode_enum(enum, value, json_encode)
  end
end
