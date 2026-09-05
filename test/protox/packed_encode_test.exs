defmodule Protox.PackedEncodeTest do
  use ExUnit.Case, async: true

  import Bitwise

  alias ProtobufTestMessages.Proto3.TestAllTypesProto3
  alias Protox.{Encode, Varint, Zigzag}

  # LEB128 size thresholds: first/last value of each encoded width.
  @varint_boundaries [0, 1] ++
                       Enum.flat_map(1..9, fn n -> [(1 <<< (7 * n)) - 1, 1 <<< (7 * n)] end) ++
                       [(1 <<< 64) - 1]

  defp varint_bytes(v), do: Varint.encode(v)

  defp int32_wire(v) when v >= 0, do: varint_bytes(v &&& 0xFFFF_FFFF)
  defp int32_wire(v), do: varint_bytes(v &&& 0xFFFF_FFFF_FFFF_FFFF)

  describe "Varint.append/2" do
    test "matches Varint.encode/1 at every LEB128 width boundary" do
      for v <- @varint_boundaries do
        assert Varint.append(<<>>, v) == varint_bytes(v)
      end
    end

    test "appends to a non-empty accumulator" do
      for v <- @varint_boundaries do
        assert Varint.append(<<1, 2, 3>>, v) == <<1, 2, 3>> <> varint_bytes(v)
      end
    end
  end

  describe "packed appenders" do
    test "empty input returns the accumulator" do
      assert Encode.encode_packed_int32([], <<>>) == <<>>
      assert Encode.encode_packed_fixed32([], <<1>>) == <<1>>
    end

    test "int32/int64: positive, negative and boundary values" do
      values = [0, 1, 127, 128, -1, 2_147_483_647, -2_147_483_648]

      expected_32 =
        values
        |> Enum.map(&int32_wire/1)
        |> IO.iodata_to_binary()

      expected_64 =
        values
        |> Enum.map(&varint_bytes(&1 &&& 0xFFFF_FFFF_FFFF_FFFF))
        |> IO.iodata_to_binary()

      assert Encode.encode_packed_int32(values, <<>>) == expected_32
      assert Encode.encode_packed_int64(values, <<>>) == expected_64
    end

    test "sint: zigzag encoding, both widths through the shared appender" do
      values = [0, -1, 1, -2_147_483_648, 2_147_483_647, -9_223_372_036_854_775_808]

      expected =
        values
        |> Enum.map(&varint_bytes(Zigzag.encode(&1)))
        |> IO.iodata_to_binary()

      assert Encode.encode_packed_sint(values, <<>>) == expected
    end

    test "fixed widths, signed values through the shared appenders" do
      assert Encode.encode_packed_fixed32([1, -1], <<>>) ==
               <<1::unsigned-little-32, -1::signed-little-32>>

      assert Encode.encode_packed_fixed64([1, -1], <<>>) ==
               <<1::unsigned-little-64, -1::signed-little-64>>
    end

    test "float/double: special values interleaved with finite ones" do
      values = [1.5, :infinity, :"-infinity", :nan, -2.5]

      # parse_repeated_* return the elements in reverse wire order (the generated
      # finish-decode step performs the single restoring reverse).
      packed_double = Encode.encode_packed_double(values, <<>>)
      assert byte_size(packed_double) == 5 * 8
      assert Protox.Decode.parse_repeated_double([], packed_double) == Enum.reverse(values)

      packed_float = Encode.encode_packed_float(values, <<>>)
      assert byte_size(packed_float) == 5 * 4
      assert Protox.Decode.parse_repeated_float([], packed_float) == Enum.reverse(values)
    end

    test "bool and enum" do
      assert Encode.encode_packed_bool([true, false, true], <<>>) == <<1, 0, 1>>

      encode_enum_fun = &TestAllTypesProto3.NestedEnum.encode/1

      # :NEG maps to -1: encoded as a 64-bit two's complement, ten bytes.
      assert Encode.encode_packed_enum([:FOO, :BAR, :NEG], <<>>, encode_enum_fun) ==
               <<0, 1>> <> int32_wire(-1)
    end
  end

  describe "generated encoders" do
    test "packed fields produce the appender output prefixed with key and length" do
      values = [1, -1, 300]
      msg = %TestAllTypesProto3{packed_int32: values}

      packed = Encode.encode_packed_int32(values, <<>>)
      {key, _size} = Encode.make_key_bytes(75, :packed)
      len = varint_bytes(byte_size(packed))

      {iodata, size} = TestAllTypesProto3.encode!(msg)
      bytes = IO.iodata_to_binary(iodata)

      assert bytes == IO.iodata_to_binary([key, len, packed])
      assert size == byte_size(bytes)
    end

    test "scalar varint boundaries round-trip and match the wire contract" do
      for v <- [1, -1, 2_147_483_647, -2_147_483_648] do
        msg = %TestAllTypesProto3{optional_int32: v}
        {iodata, _size} = TestAllTypesProto3.encode!(msg)
        bytes = IO.iodata_to_binary(iodata)

        {key, _size} = Encode.make_key_bytes(1, :int32)
        assert bytes == IO.iodata_to_binary([key, int32_wire(v)])
        assert TestAllTypesProto3.decode!(bytes).optional_int32 == v
      end
    end

    test "field encoders thread the accumulator in tag order" do
      msg = %TestAllTypesProto3{optional_int32: 1, optional_int64: 2, optional_uint32: 3}
      {iodata, _size} = TestAllTypesProto3.encode!(msg)

      # Fields are prepended from the highest tag down: the wire output is in
      # ascending tag order (1, 2, 3).
      assert IO.iodata_to_binary(iodata) == <<8, 1, 16, 2, 24, 3>>
    end

    test "populated repeated fields are reversed, untouched ones stay empty" do
      msg = %TestAllTypesProto3{repeated_int32: [1, 2, 3], packed_sint64: [-1, 1]}
      {iodata, _size} = TestAllTypesProto3.encode!(msg)
      decoded = TestAllTypesProto3.decode!(IO.iodata_to_binary(iodata))

      assert decoded.repeated_int32 == [1, 2, 3]
      assert decoded.packed_sint64 == [-1, 1]
      assert decoded.repeated_string == []
      assert decoded.packed_int32 == []
    end
  end
end
