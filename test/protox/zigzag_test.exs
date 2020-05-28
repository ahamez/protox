defmodule Protox.ZigzagTest do
  use ExUnit.Case
  use PropCheck

  test "Zigzag encode" do
    assert Protox.Zigzag.encode(0) == 0
    assert Protox.Zigzag.encode(-1) == 1
    assert Protox.Zigzag.encode(1) == 2
    assert Protox.Zigzag.encode(-2) == 3
    assert Protox.Zigzag.encode(2_147_483_647) == 4_294_967_294
    assert Protox.Zigzag.encode(-2_147_483_648) == 4_294_967_295
  end

  property "Zigzag encode" do
    forall value <- integer() do
      Protox.Zigzag.encode(value) >= 0
    end
  end

  test "Zigzag decode" do
    assert Protox.Zigzag.decode(0) == 0
    assert Protox.Zigzag.decode(1) == -1
    assert Protox.Zigzag.decode(2) == 1
    assert Protox.Zigzag.decode(3) == -2
    assert Protox.Zigzag.decode(4_294_967_294) == 2_147_483_647
    assert Protox.Zigzag.decode(4_294_967_295) == -2_147_483_648
  end

  property "Zigzag decode" do
    forall value <- range(0, 4_294_967_295) do
      decoded = Protox.Zigzag.decode(value)
      decoded <= 2_147_483_647 and decoded >= -2_147_483_648
    end
  end

  test "Symmetric" do
    forall value <- integer() do
      value == value |> Protox.Zigzag.encode() |> Protox.Zigzag.decode()
    end
  end
end
