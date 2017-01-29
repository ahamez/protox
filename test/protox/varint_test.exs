defmodule Protox.VarintTest do
  use ExUnit.Case


  test "Encode" do
    assert Protox.Varint.encode(300) == [<<172>>, <<2>>]
    assert Protox.Varint.encode(0)   == <<0>>
    assert Protox.Varint.encode(1)   == <<1>>
  end


  test "Decode" do
    assert Protox.Varint.decode(<<172, 2>>)        == {300  , <<>>}
    assert Protox.Varint.decode(<<172, 2, 0>>)     == {300  , <<0>>}
    assert Protox.Varint.decode(<<0>>)             == {0    , <<>>}
    assert Protox.Varint.decode(<<1>>)             == {1    , <<>>}
    assert Protox.Varint.decode(<<185, 96>>)       == {12345, <<>>}
    assert Protox.Varint.decode(<<185, 224, 0>>)   == {12345, <<>>}
  end

end
