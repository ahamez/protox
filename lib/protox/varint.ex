defmodule Protox.Varint do
  @moduledoc false
  # Internal. Implement LEB128 compression.

  import Bitwise

  @spec encode(integer) :: binary()
  def encode(v) when v < 1 <<< 7,
    do: <<v>>

  def encode(v) when v < 1 <<< 14,
    do: <<1::1, v::7, v >>> 7>>

  def encode(v) when v < 1 <<< 21,
    do: <<1::1, v::7, 1::1, v >>> 7::7, v >>> 14>>

  def encode(v) when v < 1 <<< 28,
    do: <<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, v >>> 21>>

  def encode(v) when v < 1 <<< 35,
    do: <<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, v >>> 28>>

  def encode(v) when v < 1 <<< 42,
    do:
      <<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
        v >>> 35>>

  def encode(v) when v < 1 <<< 49,
    do:
      <<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
        1::1, v >>> 35::7, v >>> 42>>

  def encode(v) when v < 1 <<< 56,
    do:
      <<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
        1::1, v >>> 35::7, 1::1, v >>> 42::7, v >>> 49>>

  def encode(v), do: <<1::1, v::7, encode(v >>> 7)::binary>>

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
    raise Protox.DecodingError.new(binary, "invalid varint")
  end
end
