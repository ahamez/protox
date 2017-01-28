defmodule Protox.Varint do

  @moduledoc false

  use Bitwise

  @spec encode(integer) :: iodata
  def encode(v) when v < 128, do: <<v>>
  def encode(v)             , do: [<<1::1, v::7>>, encode(v >>> 7)]

end
