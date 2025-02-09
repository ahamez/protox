defmodule Protox.EncodeTest do
  use ExUnit.Case

  alias ProtobufTestMessages.Proto3.{NullHypothesisProto3, TestAllTypesProto3}

  test "Default TestAllTypesProto3" do
    assert %TestAllTypesProto3{} |> Protox.encode!() == {[], 0}
  end

  test "Default TestAllTypesProto3, with non throwing encode/1" do
    assert {:ok, [], 0} == Protox.encode(%TestAllTypesProto3{})
  end

  test "Messsage with no fields, unknown fields are encoded back" do
    msg = %NullHypothesisProto3{
      __uf__: [
        {1, 0, "*"},
        {3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>},
        {10_001, 0, "S"}
      ]
    }

    assert encode(msg) ==
             {<<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>, 15}
  end

  test "Scalar int64" do
    assert encode(%TestAllTypesProto3{optional_int64: -300}) ==
             {<<16, 212, 253, 255, 255, 255, 255, 255, 255, 255, 1>>, 11}
  end

  test "Scalar uint32" do
    assert encode(%TestAllTypesProto3{optional_uint32: 42}) == {<<24, 42>>, 2}
  end

  test "Scalar uint64" do
    assert encode(%TestAllTypesProto3{optional_uint64: 300_000}) == {<<32, 224, 167, 18>>, 4}
  end

  test "Scalar sint64" do
    assert encode(%TestAllTypesProto3{optional_sint64: -1323}) == {<<48, 213, 20>>, 3}
  end

  test "Scalar fixed32" do
    assert encode(%TestAllTypesProto3{optional_fixed32: 352}) == {<<61, 96, 1, 0, 0>>, 5}
  end

  test "Scalar sfixed64" do
    assert encode(%TestAllTypesProto3{optional_sfixed64: -352}) ==
             {<<81, 160, 254, 255, 255, 255, 255, 255, 255>>, 9}
  end

  test "Repeated int32" do
    assert encode(%TestAllTypesProto3{repeated_int32: [-1, 0, 1]}) ==
             {<<250, 1, 12, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 0, 1>>, 15}
  end

  test "Repeated fixed64" do
    assert encode(%TestAllTypesProto3{repeated_fixed64: [0, 1]}) ==
             {<<178, 2, 16, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0>>, 19}
  end

  test "Repeated sfixed32" do
    assert encode(%TestAllTypesProto3{repeated_sfixed32: [-1, 2]}) ==
             {<<186, 2, 8, 255, 255, 255, 255, 2, 0, 0, 0>>, 11}
  end

  test "Repeated double" do
    assert encode(%TestAllTypesProto3{
             repeated_double: [33.2, -44.0, :infinity, :"-infinity", :nan]
           }) ==
             {<<210, 2, 40, 154, 153, 153, 153, 153, 153, 64, 64, 0, 0, 0, 0, 0, 0, 70, 192, 0, 0,
                0, 0, 0, 0, 240, 127, 0, 0, 0, 0, 0, 0, 240, 255, 0, 0, 0, 0, 0, 1, 241, 255>>,
              43}
  end

  test "Repeated float" do
    assert encode(%TestAllTypesProto3{
             repeated_float: [33.2, -44.0, :infinity, :"-infinity", :nan]
           }) ==
             {<<202, 2, 20, 205, 204, 4, 66, 0, 0, 48, 194, 0, 0, 128, 127, 0, 0, 128, 255, 0, 1,
                129, 255>>, 23}
  end

  test "Repeated bool" do
    assert encode(%TestAllTypesProto3{repeated_bool: [true, false, true, false, false, false]}) ==
             {<<218, 2, 6, 1, 0, 1, 0, 0, 0>>, 9}
  end

  test "Repeated enum" do
    assert encode(%TestAllTypesProto3{repeated_nested_enum: [:FOO, :BAR, :BAZ, 4]}) ==
             {<<154, 3, 4, 0, 1, 2, 4>>, 7}
  end

  test "Unpacked Repeated int32" do
    assert encode(%TestAllTypesProto3{unpacked_int32: [-1, 2, 3]}) ==
             {<<200, 5, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 200, 5, 2, 200, 5, 3>>,
              18}
  end

  test "Bytes" do
    assert encode(%TestAllTypesProto3{optional_bytes: <<1, 2, 3>>}) ==
             {<<122, 3, 1, 2, 3>>, 5}
  end

  test "Unknown fields (float + varint + bytes)" do
    assert %TestAllTypesProto3{
             __uf__: [
               {12, 5, <<236, 81, 5, 66>>},
               {11, 0, <<154, 5>>},
               {10, 2, <<104, 101, 121, 33>>}
             ]
           }
           |> encode() ==
             {<<101, 236, 81, 5, 66, 88, 154, 5, 82, 4, 104, 101, 121, 33>>, 14}
  end

  test "Empty repeated bool" do
    assert encode(%TestAllTypesProto3{repeated_bool: []}) == {"", 0}
  end

  test "Optional sub message" do
    assert encode(%OptionalMsg3{foo: %OptionalMsg1{foo: 42}}) == {<<10, 2, 8, 42>>, 4}
  end

  test "Do not output default double/float" do
    assert encode(%TestAllTypesProto3{optional_float: 0.0, optional_double: 0.0}) == {<<>>, 0}
    assert encode(%TestAllTypesProto3{optional_float: 0, optional_double: 0}) == {<<>>, 0}
  end

  test "Raise when required field is missing" do
    exception =
      assert_raise Protox.RequiredFieldsError, "Some required fields are not set: [:a]", fn ->
        Protox.encode!(%Protobuf2Required{})
      end

    assert exception.missing_fields == [:a]
  end

  test "UTF-8 strings" do
    [
      {"", {<<>>, 0}},
      {"hello, 漢字, 💻, 🏁, working fine", {<<114, 39, "hello, 漢字, 💻, 🏁, working fine">>, 41}}
    ]
    |> Enum.each(fn {string, expected_encoded_msg} ->
      assert encode(%TestAllTypesProto3{optional_string: string}) == expected_encoded_msg
    end)
  end

  test "Largest valid string" do
    string_size = Protox.String.max_size()

    assert encode(%TestAllTypesProto3{optional_string: <<0::integer-size(string_size)-unit(8)>>}) ==
             {<<114, 128, 128, 64>> <> <<0::integer-size(string_size)-unit(8)>>, string_size + 4}
  end

  test "Map" do
    msg = %TestAllTypesProto3{map_int32_int32: %{1 => 2, 3 => 4}}

    {bytes, size} = Protox.encode!(msg)
    assert size == bytes |> IO.iodata_to_binary() |> byte_size()
  end

  test "Raise when string is not valid UTF-8" do
    [
      <<128>>,
      <<?a, 128>>,
      <<128, ?a>>,
      <<?a, 255, ?b>>,
      <<255, 255, 255, 255>>
    ]
    |> Enum.each(fn string ->
      assert_raise Protox.EncodingError, ~r/Could not encode field :optional_string /, fn ->
        %TestAllTypesProto3{optional_string: string}
        |> Protox.encode!()
      end
    end)
  end

  test "Raise when repeated string is not valid UTF-8" do
    [
      [<<128>>, "hello"],
      ["hello", <<128>>]
    ]
    |> Enum.each(fn strings ->
      assert_raise Protox.EncodingError, ~r/Could not encode field :repeated_string /, fn ->
        %TestAllTypesProto3{repeated_string: strings} |> Protox.encode!()
      end
    end)
  end

  test "Raise when string is too large" do
    string_size = Protox.String.max_size() + 1

    assert_raise(Protox.EncodingError, ~r/Could not encode field :optional_string /, fn ->
      %TestAllTypesProto3{optional_string: <<0::integer-size(string_size)-unit(8)>>}
      |> Protox.encode!()
    end)
  end

  defp encode(msg) do
    {iodata, size} = Protox.encode!(msg)

    {IO.iodata_to_binary(iodata), size}
  end
end
