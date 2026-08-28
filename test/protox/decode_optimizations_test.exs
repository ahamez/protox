defmodule Protox.DecodeOptimizationsTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias ProtobufTestMessages.Proto3.TestAllTypesProto3

  describe "known tag with an unexpected wire type" do
    test "is kept as an unknown field instead of being misparsed" do
      # optional_int32 has tag 1 and varint wire type; encode it with the
      # 32-bit wire type (key byte 13) instead.
      bytes = <<13, 1, 2, 3, 4>>
      msg = TestAllTypesProto3.decode!(bytes)

      assert msg.optional_int32 == 0
      assert TestAllTypesProto3.unknown_fields(msg) == [{1, 5, <<1, 2, 3, 4>>}]
    end

    test "does not prevent decoding subsequent known fields" do
      bytes = <<13, 1, 2, 3, 4, 8, 42>>
      msg = TestAllTypesProto3.decode!(bytes)

      assert msg.optional_int32 == 42
      assert TestAllTypesProto3.unknown_fields(msg) == [{1, 5, <<1, 2, 3, 4>>}]
    end
  end

  # parse_repeated_* prepend onto their accumulator: they return the elements in
  # reverse wire order, and the generated finish-decode step performs the single
  # reverse that restores wire order.
  describe "packed fixed-width fast path" do
    test "decodes element counts around the four-element unroll boundary" do
      for count <- 1..9 do
        values = Enum.to_list(1..count)
        bytes = for v <- values, into: <<>>, do: <<v::unsigned-little-32>>

        assert Protox.Decode.parse_repeated_fixed32([], bytes) == Enum.reverse(values)
      end
    end

    test "decodes NaN and infinities interleaved with finite packed doubles" do
      values = [1.0, :nan, 2.0, 3.0, 4.0, 5.0, :infinity, :"-infinity", 6.0]

      bytes = Protox.Encode.encode_packed_double(values, <<>>)

      assert Protox.Decode.parse_repeated_double([], bytes) == Enum.reverse(values)
    end

    test "raises on a truncated packed fixed32 payload" do
      assert_raise Protox.DecodingError, fn ->
        Protox.Decode.parse_repeated_fixed32([], <<1, 2, 3>>)
      end
    end
  end

  describe "varint scalar truncation boundaries" do
    test "int32 sign boundaries" do
      # -1 as an int32 arrives as a 10-byte varint (2^64 - 1).
      assert decode_int32((1 <<< 64) - 1) == -1
      assert decode_int32(0x7FFF_FFFF) == 2_147_483_647
      assert decode_int32(0x8000_0000) == -2_147_483_648
    end

    test "uint32 wraps values above 2^32" do
      assert decode_uint32((1 <<< 32) + 5) == 5
      assert decode_uint32((1 <<< 32) - 1) == 4_294_967_295
    end

    test "int64 sign boundaries" do
      assert decode_int64((1 <<< 63) - 1) == 9_223_372_036_854_775_807
      assert decode_int64(1 <<< 63) == -9_223_372_036_854_775_808
    end
  end

  defp decode_int32(varint_value), do: decode_with(&Protox.Decode.parse_int32/1, varint_value)
  defp decode_int64(varint_value), do: decode_with(&Protox.Decode.parse_int64/1, varint_value)
  defp decode_uint32(varint_value), do: decode_with(&Protox.Decode.parse_uint32/1, varint_value)

  defp decode_with(parse_fun, varint_value) do
    {value, <<>>} =
      varint_value
      |> Protox.Varint.encode()
      |> elem(0)
      |> parse_fun.()

    value
  end
end
