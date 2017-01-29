defmodule Protox.ZigzagTest do
  use ExUnit.Case


  test "Encode" do
    assert Protox.Zigzag.encode(0)           == 0
    assert Protox.Zigzag.encode(-1)          == 1
    assert Protox.Zigzag.encode(1)           == 2
    assert Protox.Zigzag.encode(-2)          == 3
    assert Protox.Zigzag.encode(2147483647)  == 4294967294
    assert Protox.Zigzag.encode(-2147483648) == 4294967295
  end


  test "Decode" do
    assert Protox.Zigzag.decode(0)          == 0
    assert Protox.Zigzag.decode(1)          == -1
    assert Protox.Zigzag.decode(2)          == 1
    assert Protox.Zigzag.decode(3)          == -2
    assert Protox.Zigzag.decode(4294967294) == 2147483647
    assert Protox.Zigzag.decode(4294967295) == -2147483648
  end

end
