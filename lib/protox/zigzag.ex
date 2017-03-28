defmodule Protox.Zigzag do
  @moduledoc false

  use Bitwise


  @spec encode(integer) :: non_neg_integer
  def encode(v) when v >= 0, do: v * 2
  def encode(v)            , do: v * -2 -1


  @spec decode(non_neg_integer) :: integer
  def decode(v) when (v &&& 1) == 0, do: v >>> 1
  def decode(v)                    , do: -((v + 1) >>> 1)

end
