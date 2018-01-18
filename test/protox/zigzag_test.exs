defmodule Protox.ZigzagTest do
  use ExUnit.Case

  test "Encode" do
    assert Protox.Zigzag.encode(0) == 0
    assert Protox.Zigzag.encode(-1) == 1
    assert Protox.Zigzag.encode(1) == 2
    assert Protox.Zigzag.encode(-2) == 3
    assert Protox.Zigzag.encode(2_147_483_647) == 4_294_967_294
    assert Protox.Zigzag.encode(-2_147_483_648) == 4_294_967_295
  end

  test "Decode" do
    assert Protox.Zigzag.decode(0) == 0
    assert Protox.Zigzag.decode(1) == -1
    assert Protox.Zigzag.decode(2) == 1
    assert Protox.Zigzag.decode(3) == -2
    assert Protox.Zigzag.decode(4_294_967_294) == 2_147_483_647
    assert Protox.Zigzag.decode(4_294_967_295) == -2_147_483_648
  end
end
