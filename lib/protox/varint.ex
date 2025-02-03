defmodule Protox.Varint do
  @moduledoc false
  # Internal. Implement LEB128 compression.

  import Bitwise

  @spec encode(integer) :: {binary(), non_neg_integer()}
  def encode(v) when v < 1 <<< 7,
    do: {<<v>>, 1}

  def encode(v) when v < 1 <<< 14,
    do: {<<1::1, v::7, v >>> 7>>, 2}

  def encode(v) when v < 1 <<< 21,
    do: {<<1::1, v::7, 1::1, v >>> 7::7, v >>> 14>>, 3}

  def encode(v) when v < 1 <<< 28,
    do: {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, v >>> 21>>, 4}

  def encode(v) when v < 1 <<< 35,
    do: {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, v >>> 28>>, 5}

  def encode(v) when v < 1 <<< 42,
    do:
      {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
         v >>> 35>>, 6}

  def encode(v) when v < 1 <<< 49,
    do:
      {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
         1::1, v >>> 35::7, v >>> 42>>, 7}

  def encode(v) when v < 1 <<< 56,
    do:
      {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7,
         1::1, v >>> 35::7, 1::1, v >>> 42::7, v >>> 49>>, 8}

  def encode(v) do
    {next_bytes, size} = encode(v >>> 7)
    {<<1::1, v::7, next_bytes::binary>>, size + 1}
  end

  @spec decode(binary) :: {non_neg_integer, binary}
  def decode(<<0::1, byte0::7, rest::binary>>),
    do: {byte0, rest}

  def decode(<<1::1, byte1::7, 0::1, byte0::7, rest::binary>>),
    do: {byte1 <<< 0 ||| byte0 <<< 7, rest}

  def decode(<<1::1, byte2::7, 1::1, byte1::7, 0::1, byte0::7, rest::binary>>),
    do: {byte2 <<< 0 ||| byte1 <<< 7 ||| byte0 <<< 14, rest}

  def decode(<<1::1, byte3::7, 1::1, byte2::7, 1::1, byte1::7, 0::1, byte0::7, rest::binary>>),
    do: {byte3 <<< 0 ||| byte2 <<< 7 ||| byte1 <<< 14 ||| byte0 <<< 21, rest}

  def decode(
        <<1::1, byte4::7, 1::1, byte3::7, 1::1, byte2::7, 1::1, byte1::7, 0::1, byte0::7,
          rest::binary>>
      ),
      do: {byte4 <<< 0 ||| byte3 <<< 7 ||| byte2 <<< 14 ||| byte1 <<< 21 ||| byte0 <<< 28, rest}

  def decode(
        <<1::1, byte5::7, 1::1, byte4::7, 1::1, byte3::7, 1::1, byte2::7, 1::1, byte1::7, 0::1,
          byte0::7, rest::binary>>
      ),
      do:
        {byte5 <<< 0 ||| byte4 <<< 7 ||| byte3 <<< 14 ||| byte2 <<< 21 ||| byte1 <<< 28 |||
           byte0 <<< 35, rest}

  def decode(
        <<1::1, byte6::7, 1::1, byte5::7, 1::1, byte4::7, 1::1, byte3::7, 1::1, byte2::7, 1::1,
          byte1::7, 0::1, byte0::7, rest::binary>>
      ),
      do:
        {byte6 <<< 0 ||| byte5 <<< 7 ||| byte4 <<< 14 ||| byte3 <<< 21 ||| byte2 <<< 28 |||
           byte1 <<< 35 |||
           byte0 <<< 42, rest}

  def decode(
        <<1::1, byte7::7, 1::1, byte6::7, 1::1, byte5::7, 1::1, byte4::7, 1::1, byte3::7, 1::1,
          byte2::7, 1::1, byte1::7, 0::1, byte0::7, rest::binary>>
      ),
      do:
        {byte7 <<< 0 ||| byte6 <<< 7 ||| byte5 <<< 14 ||| byte4 <<< 21 ||| byte3 <<< 28 |||
           byte2 <<< 35 |||
           byte1 <<< 42 |||
           byte0 <<< 49, rest}

  def decode(b), do: do_decode(0, 0, b)

  # -- Private

  @spec do_decode(non_neg_integer, non_neg_integer, binary) :: {non_neg_integer, binary}
  defp do_decode(result, shift, <<0::1, byte::7, rest::binary>>) do
    {result ||| byte <<< shift, rest}
  end

  defp do_decode(result, shift, <<1::1, byte::7, rest::binary>>) do
    do_decode(result ||| byte <<< shift, shift + 7, rest)
  end

  defp do_decode(_result, _shift, bytes) do
    raise Protox.DecodingError.new(bytes, "invalid varint")
  end
end
