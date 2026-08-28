defmodule Protox.Varint do
  @moduledoc false
  # Internal. Implement LEB128 compression.

  import Bitwise

  alias Protox.Varint.DecodeClauses

  @spec encode(integer) :: {binary(), non_neg_integer()}
  def encode(v) when v < 1 <<< 7, do: {<<v>>, 1}

  def encode(v) when v < 1 <<< 14, do: {<<1::1, v::7, v >>> 7>>, 2}

  def encode(v) when v < 1 <<< 21, do: {<<1::1, v::7, 1::1, v >>> 7::7, v >>> 14>>, 3}

  def encode(v) when v < 1 <<< 28, do: {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, v >>> 21>>, 4}

  def encode(v) when v < 1 <<< 35,
    do: {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, v >>> 28>>, 5}

  def encode(v) when v < 1 <<< 42,
    do: {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, v >>> 35>>, 6}

  def encode(v) when v < 1 <<< 49,
    do:
      {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1, v >>> 35::7,
         v >>> 42>>, 7}

  def encode(v) when v < 1 <<< 56,
    do:
      {<<1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1, v >>> 35::7, 1::1,
         v >>> 42::7, v >>> 49>>, 8}

  def encode(v) do
    {next_bytes, size} = encode(v >>> 7)
    {<<1::1, v::7, next_bytes::binary>>, size + 1}
  end

  # Appends the LEB128 encoding of `v` to `acc`: lets callers build a packed
  # binary without one intermediate binary per element. Not used by encode/1:
  # a standalone varint built by appending to <<>> would be an over-allocated
  # writable binary, measurably worse than the exact-sized clauses above.
  @spec append(binary(), non_neg_integer()) :: binary()
  def append(acc, v) when v < 1 <<< 7, do: <<acc::binary, v>>

  def append(acc, v) when v < 1 <<< 14, do: <<acc::binary, 1::1, v::7, v >>> 7>>

  def append(acc, v) when v < 1 <<< 21, do: <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, v >>> 14>>

  def append(acc, v) when v < 1 <<< 28, do: <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, v >>> 21>>

  def append(acc, v) when v < 1 <<< 35,
    do: <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, v >>> 28>>

  def append(acc, v) when v < 1 <<< 42,
    do: <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, v >>> 35>>

  def append(acc, v) when v < 1 <<< 49,
    do:
      <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1,
        v >>> 35::7, v >>> 42>>

  def append(acc, v) when v < 1 <<< 56,
    do:
      <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1,
        v >>> 35::7, 1::1, v >>> 42::7, v >>> 49>>

  def append(acc, v) when v < 1 <<< 63,
    do:
      <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1,
        v >>> 35::7, 1::1, v >>> 42::7, 1::1, v >>> 49::7, v >>> 56>>

  # Ten bytes: any 64-bit-truncated negative scalar lands here.
  def append(acc, v) when v < 1 <<< 64,
    do:
      <<acc::binary, 1::1, v::7, 1::1, v >>> 7::7, 1::1, v >>> 14::7, 1::1, v >>> 21::7, 1::1, v >>> 28::7, 1::1,
        v >>> 35::7, 1::1, v >>> 42::7, 1::1, v >>> 49::7, 1::1, v >>> 56::7, v >>> 63>>

  def append(acc, v) do
    append(<<acc::binary, 1::1, v::7>>, v >>> 7)
  end

  # One unrolled clause per encoded length; the clauses are shared with the
  # packed varint loops of Protox.Decode through Protox.Varint.DecodeClauses.
  varint_rest = Macro.var(:rest, __MODULE__)

  @spec decode(binary) :: {non_neg_integer, binary}
  for {pattern, value} <- DecodeClauses.build(1..8, varint_rest) do
    def decode(unquote(pattern)), do: {unquote(value), unquote(varint_rest)}
  end

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
