defmodule Protox.VarintTest do
  import Bitwise
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "Unrolled encoding produces the same result as the reference implementation" do
    check all(int <- integer(0..(1 <<< 64))) do
      assert int |> Protox.Varint.encode() |> IO.iodata_to_binary() ==
               int |> encode_reference() |> IO.iodata_to_binary()
    end
  end

  property "Symmetric" do
    check all(int <- integer(0..(1 <<< 64))) do
      assert int |> Protox.Varint.encode() |> IO.iodata_to_binary() |> Protox.Varint.decode() ==
               {int, ""}
    end
  end

  test "Encode" do
    assert Protox.Varint.encode(0) == <<0>>
    assert Protox.Varint.encode(1) == <<1>>

    assert Protox.Varint.encode((1 <<< 14) - 1) == <<0xFF, 0x7F>>
    assert Protox.Varint.encode(1 <<< 14) == <<0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 21) - 1) == <<0xFF, 0xFF, 0x7F>>
    assert Protox.Varint.encode(1 <<< 21) == <<0x80, 0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 28) - 1) == <<0xFF, 0xFF, 0xFF, 0x7F>>
    assert Protox.Varint.encode(1 <<< 28) == <<0x80, 0x80, 0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 35) - 1) == <<0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>
    assert Protox.Varint.encode(1 <<< 35) == <<0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 42) - 1) == <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>
    assert Protox.Varint.encode(1 <<< 42) == <<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 56) - 1) ==
             <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>

    assert Protox.Varint.encode(1 <<< 56) ==
             <<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>

    assert Protox.Varint.encode((1 <<< 63) - 1) ==
             <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>

    assert Protox.Varint.encode(1 <<< 63) ==
             <<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>
  end

  defp encode_reference(v) when v < 1 <<< 7, do: <<v>>
  defp encode_reference(v), do: [<<1::1, v::7>>, encode_reference(v >>> 7)]
end
