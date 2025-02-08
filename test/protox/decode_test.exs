defmodule Protox.DecodeTest do
  use ExUnit.Case

  import Bitwise

  alias ProtobufTestMessages.Proto3.{
    NullHypothesisProto3,
    TestAllTypesProto3,
    TestAllTypesProto3.NestedMessage
  }

  varint_of_max_string_size =
    Protox.String.max_size()
    |> Protox.Varint.encode()
    |> elem(0)
    |> IO.iodata_to_binary()

  @success_tests [
    {
      "Unknown fields",
      <<186, 62, 4, 104, 101, 121, 33, 176, 62, 42>>,
      %TestAllTypesProto3{__uf__: [{999, 2, <<104, 101, 121, 33>>}, {998, 0, <<42>>}]}
    },
    {
      "Repeated fixed64, not contiguous, should be concatenated",
      #   first part of repeated fixed64 |     XXXX    | second part of repeated fixed64
      <<178, 2, 8, 1, 0, 0, 0, 0, 0, 0, 0, 8, 150, 1, 178, 2, 8, 254, 255, 255, 255, 255, 255,
        255, 255>>,
      %TestAllTypesProto3{optional_int32: 150, repeated_fixed64: [1, 18_446_744_073_709_551_614]}
    },
    {
      "Repeated sfixed32",
      <<186, 2, 8, 255, 255, 255, 255, 254, 255, 255, 255>>,
      %TestAllTypesProto3{repeated_sfixed32: [-1, -2]}
    },
    {
      "Unpacked repeated int32",
      <<200, 5, 1, 200, 5, 2, 200, 5, 3>>,
      %TestAllTypesProto3{unpacked_int32: [1, 2, 3]}
    },
    {
      "Repeated enum, with one unknown value",
      <<154, 3, 4, 0, 1, 0, 3>>,
      %TestAllTypesProto3{repeated_nested_enum: [:FOO, :BAR, :FOO, 3]}
    },
    {
      "Repeated bool, packed and unpacked, should be concatenated (1)",
      # packed <> unpacked
      <<218, 2, 2, 1, 0>> <> <<218, 2, 1, 1, 218, 2, 1, 0>>,
      %TestAllTypesProto3{repeated_bool: [true, false, true, false]}
    },
    {
      "Repeated uint32",
      <<138, 2, 6, 0, 1, 2, 3, 144, 78>>,
      %TestAllTypesProto3{repeated_uint32: [0, 1, 2, 3, 10_000]}
    },
    {
      "Repeated sint32",
      <<154, 2, 7, 0, 1, 4, 5, 160, 156, 1>>,
      %TestAllTypesProto3{repeated_sint32: [0, -1, 2, -3, 10_000]}
    },
    {
      "Repeated int64",
      <<130, 2, 24, 0, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1, 2, 253, 255, 255, 255, 255,
        255, 255, 255, 255, 1, 144, 78>>,
      %TestAllTypesProto3{repeated_int64: [0, -1, 2, -3, 10_000]}
    },
    {
      "Repeated uint64",
      <<146, 2, 6, 0, 1, 2, 3, 144, 78>>,
      %TestAllTypesProto3{repeated_uint64: [0, 1, 2, 3, 10_000]}
    },
    {
      "sint32, overflow values > MAX UINT32",
      <<40, 130, 128, 128, 128, 16>>,
      %TestAllTypesProto3{optional_sint32: 1}
    },
    {
      "sint64, overflow values > MAX UINT64",
      <<48, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 32>>,
      %TestAllTypesProto3{optional_sint64: 0}
    },
    {
      "Repeated sint64",
      <<162, 2, 7, 0, 2, 3, 6, 159, 156, 1>>,
      %TestAllTypesProto3{repeated_sint64: [0, 1, -2, 3, -10_000]}
    },
    {
      "Repeated fixed32",
      <<170, 2, 20, 0, 0, 0, 0, 1, 0, 0, 0, 254, 255, 255, 255, 3, 0, 0, 0, 240, 216, 255, 255>>,
      %TestAllTypesProto3{repeated_fixed32: [0, 1, 4_294_967_294, 3, 4_294_957_296]}
    },
    {
      "Repeated sfixed64",
      <<194, 2, 40, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255, 255, 255, 255,
        255, 255, 3, 0, 0, 0, 0, 0, 0, 0, 240, 216, 255, 255, 255, 255, 255, 255>>,
      %TestAllTypesProto3{repeated_sfixed64: [0, 1, -2, 3, -10_000]}
    },
    {
      "Nested message",
      <<146, 1, 3, 8, 150, 1>>,
      %TestAllTypesProto3{optional_nested_message: %NestedMessage{a: 150}}
    },
    {
      "Repeated int32",
      <<250, 1, 6, 3, 142, 2, 158, 167, 5>>,
      %TestAllTypesProto3{repeated_int32: [3, 270, 86_942]}
    },
    {
      "Double",
      <<97, 246, 40, 92, 143, 194, 181, 64, 192>>,
      %TestAllTypesProto3{optional_double: -33.42}
    },
    {
      "Repeated float",
      <<202, 2, 8, 0, 0, 128, 63, 0, 0, 0, 64>>,
      %TestAllTypesProto3{repeated_float: [1.0, 2.0]}
    },
    {
      "Repeated float, +infinity and -infinity",
      <<202, 2, 8, 0, 0, 128, 127, 0, 0, 128, 255>>,
      %TestAllTypesProto3{repeated_float: [:infinity, :"-infinity"]}
    },
    {
      "Repeated float, all NaN",
      <<202, 2, 12, 0, 1, 129, 255, 0, 1, 129, 255, 0, 1, 129, 255>>,
      %TestAllTypesProto3{repeated_float: [:nan, :nan, :nan]}
    },
    {
      "Repeated double",
      <<210, 2, 16, 0, 0, 0, 0, 0, 0, 240, 63, 0, 0, 0, 0, 0, 0, 0, 64>>,
      %TestAllTypesProto3{repeated_double: [1.0, 2.0]}
    },
    {
      "Repeated double, +infinity and -infinity",
      <<210, 2, 16, 0, 0, 0, 0, 0, 0, 240, 127, 0, 0, 0, 0, 0, 0, 240, 255>>,
      %TestAllTypesProto3{repeated_double: [:infinity, :"-infinity"]}
    },
    {
      "Repeated double, all NaN",
      <<202, 2, 12, 0, 1, 129, 255, 0, 1, 129, 255, 0, 1, 129, 255>>,
      %TestAllTypesProto3{repeated_float: [:nan, :nan, :nan]}
    },
    {
      "Map string -> string",
      # |             first <key,value>          | second <key,value>
      <<170, 4, 8, 10, 1, 97, 18, 3, 97, 97, 97, 170, 4, 8, 10, 1, 98, 18, 3, 98, 98, 98>>,
      %TestAllTypesProto3{map_string_string: %{"a" => "aaa", "b" => "bbb"}}
    },
    {
      "Map string -> string, reversed",
      # |             second <key,value>          | first <key,value>
      <<170, 4, 8, 10, 1, 98, 18, 3, 98, 98, 98, 170, 4, 8, 10, 1, 97, 18, 3, 97, 97, 97>>,
      %TestAllTypesProto3{map_string_string: %{"a" => "aaa", "b" => "bbb"}}
    },
    {
      "Map string -> string, duplicated key, last one is kep",
      #                   "a" =>    "a" "a" "a"                    "a" =>    "b" "b" "b"
      <<170, 4, 8, 10, 1, 97, 18, 3, 97, 97, 97, 170, 4, 8, 10, 1, 97, 18, 3, 98, 98, 98>>,
      %TestAllTypesProto3{map_string_string: %{"a" => "bbb"}}
    },
    {
      "Map string -> string, unknown data in a map entry",
      #                   "a" =>    "a" "a" "a"  |
      #                                          | unknown data
      #                                          | (tag=3,wire_type=2, length=1, data='!')
      <<170, 4, 11, 10, 1, 97, 18, 3, 97, 97, 97, 26, 1, 33>>,
      %TestAllTypesProto3{map_string_string: %{"a" => "aaa"}}
    },
    {
      "Map string -> string, reversed inside map entry",
      #       | value               | key
      <<170, 4, 8, 18, 3, 97, 97, 97, 10, 1, 97>>,
      %TestAllTypesProto3{map_string_string: %{"a" => "aaa"}}
    },
    {
      "Map int32 -> int32, missing key",
      # Would have been <<194, 3, 4, 8, 0, 16, 42>> with the value in the map.
      <<194, 3, 2, 16, 42>>,
      %TestAllTypesProto3{map_int32_int32: %{0 => 42}}
    },
    {
      "Map int32 -> int32, missing value",
      # Would have been <<194, 3, 4, 8, 42, 16, 0>> with the value in the map.
      <<194, 3, 2, 8, 42>>,
      %TestAllTypesProto3{map_int32_int32: %{42 => 0}}
    },
    {
      "Map string -> nested message, missing value",
      # Would have been <<186, 4, 7, 10, 3, 102, 111, 111, 18, 0>> with the value in the map.
      <<186, 4, 5, 10, 3, 102, 111, 111>>,
      %TestAllTypesProto3{map_string_nested_message: %{"foo" => %NestedMessage{}}}
    },
    {
      "Map string -> nested message",
      <<186, 4, 9, 10, 3, 98, 97, 114, 18, 2, 8, 43, 186, 4, 7, 10, 3, 102, 111, 111, 18, 0>>,
      %TestAllTypesProto3{
        map_string_nested_message: %{"foo" => %NestedMessage{}, "bar" => %NestedMessage{a: 43}}
      }
    },
    {
      "Message without fields",
      <<>>,
      %NullHypothesisProto3{}
    },
    {
      "Message without fields and with unknown fields",
      <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>,
      %NullHypothesisProto3{
        __uf__: [
          {1, 0, "*"},
          {3, 1, <<246, 40, 92, 143, 194, 53, 69, 64>>},
          {10_001, 0, "S"}
        ]
      }
    },
    {
      "No name clash for __uf__",
      <<>>,
      %NoUfNameClash{__uf__: 0}
    },
    {
      "Optional nested message",
      <<146, 1, 2, 8, 42>>,
      %TestAllTypesProto3{optional_nested_message: %NestedMessage{a: 42}}
    },
    {
      "Optional nested message set to nil",
      <<>>,
      %TestAllTypesProto3{optional_nested_message: nil}
    },
    {
      "Empty string",
      <<114, 0>>,
      %TestAllTypesProto3{}
    },
    {
      "Non-ASCII string",
      <<114, 39, "hello, 漢字, 💻, 🏁, working fine">>,
      %TestAllTypesProto3{
        optional_string: "hello, 漢字, 💻, 🏁, working fine"
      }
    },
    {
      "Empty repeated string (first occurence)",
      <<226, 2, 0, 226, 2, 5, "hello">>,
      %TestAllTypesProto3{repeated_string: ["", "hello"]}
    },
    {
      "Empty repeated string (second occurence)",
      <<226, 2, 5, "hello", 226, 2, 0>>,
      %TestAllTypesProto3{repeated_string: ["hello", ""]}
    },
    {
      "Largest valid string (tests-specific limit of 1 MiB)",
      <<114>> <>
        varint_of_max_string_size <>
        <<0::integer-size(Protox.String.max_size())-unit(8)>>,
      %TestAllTypesProto3{
        optional_string: <<0::integer-size(Protox.String.max_size())-unit(8)>>
      }
    }
  ]

  min_invalid_string_size = Protox.String.max_size() + 1

  varint_of_min_invalid_string_size =
    min_invalid_string_size
    |> Protox.Varint.encode()
    |> elem(0)
    |> IO.iodata_to_binary()

  @failure_tests [
    {
      "decoding a field with tag 0 raises IllegalTagError",
      <<0>>,
      TestAllTypesProto3,
      Protox.IllegalTagError
    },
    {
      "decoding a empty struct field with tag 0 raises IllegalTagError",
      <<0>>,
      NullHypothesisProto3,
      Protox.IllegalTagError
    },
    {
      "decoding a dummy varint returns an error",
      <<255, 255, 255, 255>>,
      NullHypothesisProto3,
      Protox.DecodingError
    },
    {
      "invalid bytes for unknown delimited (len doesn't match)",
      <<18, 7, 116, 101, 115, 116>>,
      NullHypothesisProto3,
      Protox.DecodingError
    },
    {
      "can't parse unknown bytes",
      <<41, 246, 40, 92, 181, 64, 192>>,
      NullHypothesisProto3,
      Protox.DecodingError
    },
    {
      "invalid double",
      # Last byte `64` of :optional_float is missing.
      <<97, 3, 130, 148, 51, 111, 39, 98>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid float",
      # Last byte `67` of :optional_float is missing.
      <<93, 121, 59, 17>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid sfixed64",
      <<81, 0, 0, 0, 0, 0, 0, 0>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid fixed64",
      <<65, 0, 0, 0, 0, 0, 0, 0>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid sfixed32",
      <<73, 0, 0, 0>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid fixed32",
      <<57, 0, 0, 0>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid delimited (string)",
      <<114, 3, 0, 0>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid unknown varint bytes",
      # malformed varint as the first bit of 128 is '1', which
      # indicated that another byte should follow
      <<8, 128>>,
      NullHypothesisProto3,
      Protox.DecodingError
    },
    {
      "invalid string (incomplete prefix)",
      # We set field to the length delimited value <<128, ?a>>
      <<114, 2, 128, ?a>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid string (incomplete suffix)",
      # We set field to the length delimited value <<?a, 128>>
      <<114, 2, ?a, 128>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid string (incomplete infix)",
      # We set field to the length delimited value <<?a, 255, ?b>>
      <<114, 3, ?a, 255, ?b>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid UTF-8 string",
      <<114, 8, 255, 255, 255, 255, 255, 255, 255, 255>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid repeated string (1st occurence)",
      # We set first occurence of field nr 2 to the length delimited value <<128>>
      <<226, 2, 2, 128, 226, 2, 1, "hello">>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid repeated string (2nd occurance)",
      # We set second occurence of field nr 2 to the length delimited value <<128>>
      <<226, 2, 5, "hello", 226, 2, 1, 128>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "string too large (tests-specific limit of 1 MiB)",
      <<114>> <>
        varint_of_min_invalid_string_size <>
        <<0::integer-size(min_invalid_string_size)-unit(8)>>,
      TestAllTypesProto3,
      Protox.DecodingError
    },
    {
      "invalid wire type",
      <<
        # Field  |  Invalid wire type
        1 <<< 3 ||| 6,
        # Dummy value
        1
      >>,
      TestAllTypesProto3,
      Protox.DecodingError
    }
  ]

  for {description, bytes, expected} <- @success_tests do
    test "Success: can decode #{description}" do
      bytes = unquote(bytes)
      expected = unquote(Macro.escape(expected))

      assert Protox.decode!(bytes, expected.__struct__) == expected
    end
  end

  for {description, bytes, mod, exception} <- @failure_tests do
    test "Failure: should not decode #{description}" do
      bytes = unquote(bytes)
      mod = unquote(mod)

      assert_raise unquote(exception), fn ->
        Protox.decode!(bytes, mod)
      end
    end
  end

  test "Required.Proto3.ProtobufInput.ValidDataOneof.MESSAGE.Merge" do
    req1 = <<130, 7, 9, 18, 7, 8, 1, 16, 1, 200, 5, 1>>
    req2 = <<130, 7, 7, 18, 5, 16, 1, 200, 5, 1>>
    req = req1 <> req2

    m1 = TestAllTypesProto3.decode!(req1)
    m2 = TestAllTypesProto3.decode!(req2)
    m = TestAllTypesProto3.decode!(req)

    # https://developers.google.com/protocol-buffers/docs/encoding#optional
    assert m == Protox.MergeMessage.merge(m1, m2)
  end

  test "success: not error when some required fields are missing" do
    assert {:ok, %Protobuf2Required{}} = Protobuf2Required.decode(<<>>)
  end
end
