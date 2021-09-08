defmodule Protox.Varint do
  @moduledoc false
  # Internal. Implement LEB128 compression.

  use Bitwise

  @spec encode(integer) :: iodata
  def encode(v) when v < 128, do: <<v>>
  def encode(v), do: [<<1::1, v::7>>, encode(v >>> 7)]

  @spec decode(binary) :: {non_neg_integer, binary}
  def decode(b), do: do_decode(0, 0, b)

  # -- Private

  @spec do_decode(non_neg_integer, non_neg_integer, binary) :: {non_neg_integer, binary}
  defp do_decode(result, shift, <<0::1, byte::7, rest::binary>>) do
    {result ||| byte <<< shift, rest}
  end

  defp do_decode(result, shift, <<1::1, byte::7, rest::binary>>) do
    do_decode(
      result ||| byte <<< shift,
      shift + 7,
      rest
    )
  end

  defp do_decode(_result, _shift, binary) do
    raise Protox.DecodingError.new(:varint, binary)
  end
end
