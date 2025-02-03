defmodule Protox.VarintTest do
  import Bitwise
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "Unrolled encoding produces the same result as the reference implementation" do
    check all(int <- integer(0..(1 <<< 64))) do
      {unrolled, size} = Protox.Varint.encode(int)
      unrolled_bytes = IO.iodata_to_binary(unrolled)
      assert size == byte_size(unrolled_bytes)

      reference = encode_reference(int)

      assert unrolled_bytes == IO.iodata_to_binary(reference)
    end
  end

  property "Symmetric" do
    check all(int <- integer(0..(1 <<< 64))) do
      {encoded, size} = Protox.Varint.encode(int)
      assert size == byte_size(encoded)

      assert {^int, ""} = encoded |> IO.iodata_to_binary() |> Protox.Varint.decode()
    end
  end

  test "Encode" do
    assert Protox.Varint.encode(0) == {<<0>>, 1}
    assert Protox.Varint.encode(1) == {<<1>>, 1}

    assert Protox.Varint.encode((1 <<< 14) - 1) == {<<0xFF, 0x7F>>, 2}
    assert Protox.Varint.encode(1 <<< 14) == {<<0x80, 0x80, 0x1>>, 3}

    assert Protox.Varint.encode((1 <<< 21) - 1) == {<<0xFF, 0xFF, 0x7F>>, 3}
    assert Protox.Varint.encode(1 <<< 21) == {<<0x80, 0x80, 0x80, 0x1>>, 4}

    assert Protox.Varint.encode((1 <<< 28) - 1) == {<<0xFF, 0xFF, 0xFF, 0x7F>>, 4}
    assert Protox.Varint.encode(1 <<< 28) == {<<0x80, 0x80, 0x80, 0x80, 0x1>>, 5}

    assert Protox.Varint.encode((1 <<< 35) - 1) == {<<0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>, 5}
    assert Protox.Varint.encode(1 <<< 35) == {<<0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>, 6}

    assert Protox.Varint.encode((1 <<< 42) - 1) == {<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>, 6}
    assert Protox.Varint.encode(1 <<< 42) == {<<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>, 7}

    assert Protox.Varint.encode((1 <<< 56) - 1) ==
             {<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>, 8}

    assert Protox.Varint.encode(1 <<< 56) ==
             {<<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>, 9}

    assert Protox.Varint.encode((1 <<< 63) - 1) ==
             {<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>, 9}

    assert Protox.Varint.encode(1 <<< 63) ==
             {<<0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x1>>, 10}
  end

  defp encode_reference(v) when v < 1 <<< 7, do: <<v>>
  defp encode_reference(v), do: [<<1::1, v::7>>, encode_reference(v >>> 7)]
end
