defmodule Protox.VarintTest do
  use ExUnit.Case
  use PropCheck

  test "Encode" do
    assert Protox.Varint.encode(300) == [<<172>>, <<2>>]
    assert Protox.Varint.encode(0) == <<0>>
    assert Protox.Varint.encode(1) == <<1>>
  end

  test "Decode" do
    assert Protox.Varint.decode(<<172, 2>>) == {300, <<>>}
    assert Protox.Varint.decode(<<172, 2, 0>>) == {300, <<0>>}
    assert Protox.Varint.decode(<<0>>) == {0, <<>>}
    assert Protox.Varint.decode(<<1>>) == {1, <<>>}
    assert Protox.Varint.decode(<<185, 96>>) == {12_345, <<>>}
    assert Protox.Varint.decode(<<185, 224, 0>>) == {12_345, <<>>}
  end

  @tag :properties
  test "Symmetric" do
    forall value <- integer() do
      encoded = value |> Protox.Varint.encode() |> :binary.list_to_bin()
      {decoded, <<>>} = Protox.Varint.decode(encoded)

      value == decoded
    end
  end
end
