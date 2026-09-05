defmodule Protox.VarintTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Bitwise

  property "Unrolled encoding produces the same result as the reference implementation" do
    check all(int <- integer(0..(1 <<< 64))) do
      unrolled = Protox.Varint.encode(int)
      assert is_binary(unrolled)

      reference = encode_reference(int)

      assert unrolled == IO.iodata_to_binary(reference)
    end
  end

  property "Symmetric" do
    check all(int <- integer(0..(1 <<< 64))) do
      assert {^int, ""} =
               int
               |> Protox.Varint.encode()
               |> Protox.Varint.decode()
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
