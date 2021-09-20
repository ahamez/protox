# A dedicated module to make sure all messages are compiled before Protox.JsonDecodeTest.
defmodule Protox.JsonDecodeTestMessages do
  Code.require_file("./test/support/messages.exs")
end

defmodule Protox.JsonDecodeTest do
  use ExUnit.Case
  use Protox.Float

  @scalar_success_tests %{
    "{\"a\":null}" => {
      %Sub{a: 0},
      "null as default value"
    },
    "{\"a\":-1}" => {
      %Sub{a: -1},
      "int32 as number"
    },
    "{\"a\":-1.0}" => {
      %FloatPrecision{a: -1.0},
      "double as number"
    },
    "{\"a\":\"-1.0\"}" => {
      %FloatPrecision{a: -1.0},
      "double as string"
    },
    "{\"b\":-1.0}" => {
      %FloatPrecision{b: -1.0},
      "float as number"
    },
    "{\"b\":\"-1.0\"}" => {
      %FloatPrecision{b: -1.0},
      "float as string"
    },
    "{\"b\":\"-1\"}" => {
      %FloatPrecision{b: -1.0},
      "float as string without decimal"
    },
    "{\"b\": \"foo\"}" => {
      %Sub{b: "foo"},
      "string"
    },
    "{\"m\":\"AQID\"}" => {
      %Sub{m: <<1, 2, 3>>},
      "bytes"
    },
    "{\"r\":\"FOO\"}" => {
      %Sub{r: :FOO},
      "enum as string"
    },
    "{\"r\":-1}" => {
      %Sub{r: :NEG},
      "enum as number"
    },
    "{\"r\":42}" => {
      %Sub{r: 42},
      "enum as unknown number"
    },
    "{\"c\":\"-1\", \"e\":\"24\", \"l\":\"33\", \"s\":\"67\"}" =>
      {%Sub{c: -1, e: 24, l: 33, s: 67}, "int64, sfixed64, uint64, fixed64 as string"},
    "{\"c\":-1, \"e\":24, \"l\":33, \"s\": 67}" =>
      {%Sub{c: -1, e: 24, l: 33, s: 67}, "int64, sfixed64, uint64, fixed64 as numbers"},
    "{\"msgF\": {\"a\": 1}}" => {
      %Msg{msg_f: %Sub{a: 1}},
      "nested messasge"
    },
    "{\"msgN\":\"foo\"}" => {
      %Msg{msg_m: {:msg_n, "foo"}},
      "oneof set to string"
    },
    "{\"msgO\":{\"a\":1}}" => {
      %Msg{msg_m: {:msg_o, %Sub{a: 1}}},
      "oneof set to message"
    },
    "{\"i\":[1,-1.12,0.1]}" => {
      %Sub{i: [1, -1.12, 0.1]},
      "repeated double as number"
    },
    "{\"i\":[\"1\",\"-1.12\",\"0.1\"]}" => {
      %Sub{i: [1, -1.12, 0.1]},
      "repeated double as string"
    },
    "{\"msgK\":{\"2\":\"2\",\"1\":\"1\"}}" => {
      %Msg{msg_k: %{1 => "1", 2 => "2"}},
      "map int32 => string"
    },
    "{\"msgL\":{\"2\":-2.0,\"1\":1.0}}" => {
      %Msg{msg_l: %{"1" => 1.0, "2" => -2.0}},
      "map string => double"
    },
    "{\"map1\":{\"2\":\"Ag==\",\"1\":\"AQ==\"}}" => {
      %Sub{map1: %{1 => <<1>>, 2 => <<2>>}},
      "map sfixed64 => bytes"
    },
    "{\"a\":\"Infinity\"}" => {
      %FloatPrecision{a: :infinity},
      "double +infinity"
    },
    "{\"a\":\"-Infinity\"}" => {
      %FloatPrecision{a: :"-infinity"},
      "double -infinity"
    },
    "{\"a\":\"NaN\"}" => {
      %FloatPrecision{a: :nan},
      "double nan"
    },
    "{\"optionalInt32\": 100000.000}" => {
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_int32: 100_000},
      "integer with trailing zeros"
    },
    "{\"optionalInt32\": 1e5}" => {
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_int32: 100_000},
      "integer represented as float value"
    },
    "{\"optionalAliasedEnum\": \"ALIAS_BAZ\"}" => {
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_aliased_enum: :ALIAS_BAZ},
      "enum alias"
    }
  }

  @scalar_failure_tests %{
    "{\"r\":\"WRONG_ENUM_ENTRY\"}" => {
      Sub,
      "enum as unknown string"
    },
    "{\"a\":\"1.0invalid\"}" => {
      FloatPrecision,
      "invalid float"
    },
    "{\"a\":\"1invalid\"}" => {
      Sub,
      "invalid integer"
    },
    "{\"r\":\"scalar\"}" => {
      Sub,
      "already existing atom which is not part of the enum"
    },
    "{\"map1\": {\"0\": null}}" => {
      Sub,
      "map bytes entry value is null"
    },
    "{\"mapInt32Int32\": {\"0\": null}}" => {
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      "map int32 entry value is null"
    },
    "{\"optionalUint32\": 0.5}" => {
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      "float as integer"
    },
    "{\"optionalInt32\": 4.294967295e9}" => {
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      "integer represented as float value too large"
    },
    "{\"oneofUint32\": 1, \"oneofString\": \"test\"}" => {
      ProtobufTestMessages.Proto3.TestAllTypesProto3,
      "duplicate oneof"
    }
  }

  describe "Scalar types" do
    for {json, {expected, description}} <- @scalar_success_tests do
      test "Success: can decode #{description}" do
        json = unquote(json)
        expected = unquote(Macro.escape(expected))

        assert Protox.json_decode!(json, expected.__struct__) == expected
      end
    end

    for {json, {mod, description}} <- @scalar_failure_tests do
      test "Failure: should not decode #{description}" do
        json = unquote(json)
        mod = unquote(mod)

        assert_raise Protox.JsonDecodingError, fn ->
          Protox.json_decode!(json, mod)
        end
      end
    end
  end

  describe "Errors" do
    test "Failure: parsing an unknown field raises an exception" do
      json = "{\"this_field_does_not_exist\": 42}"

      assert_raise Protox.JsonDecodingError, fn ->
        Protox.json_decode!(json, Sub)
      end
    end
  end

  describe "Field names" do
    test "Success: json field name is camel case" do
      msg = %Msg{msg_e: true}
      json = "{\"msgE\":true}"
      assert Protox.json_decode!(json, Msg) == msg
    end

    test "Success: json field name is lower case" do
      msg = %Msg{msg_e: true}
      json = "{\"msg_e\":true}"
      assert Protox.json_decode!(json, Msg) == msg
    end
  end

  describe "JSON libraries" do
    setup do
      {
        :ok,
        %{
          json: "{\"a\":null, \"b\":\"foo\", \"c\": 33}",
          expected: %Sub{a: 0, b: "foo", c: 33}
        }
      }
    end

    test "Success: jason", %{json: json, expected: expected} do
      assert Protox.json_decode!(json, Sub, json_decoder: Jason) == expected
    end

    test "Success: poison", %{json: json, expected: expected} do
      assert Protox.json_decode!(json, Sub, json_decoder: Poison) == expected
    end

    test "Success: jiffy", %{json: json, expected: expected} do
      defmodule Jiffy do
        def decode!(input) do
          :jiffy.decode(input, [:return_maps, :use_nil])
        end
      end

      assert Protox.json_decode!(json, Sub, json_decoder: Protox.JsonDecodeTest.Jiffy) == expected
    end
  end
end
