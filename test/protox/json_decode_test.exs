# A dedicated module to make sure all messages are compiled before Protox.JsonDecodeTest.
defmodule Protox.JsonDecodeTestMessages do
  Code.require_file("./test/support/messages.exs")
end

defmodule Protox.JsonDecodeTest do
  use ExUnit.Case
  use Protox.Float

  @success_tests [
    {
      "null as default value",
      "{\"a\":null}",
      %Sub{a: 0}
    },
    {
      "int32 as number",
      "{\"a\":-1}",
      %Sub{a: -1}
    },
    {
      "double as number",
      "{\"a\":-1.0}",
      %FloatPrecision{a: -1.0}
    },
    {
      "double as string",
      "{\"a\":\"-1.0\"}",
      %FloatPrecision{a: -1.0}
    },
    {
      "float as number",
      "{\"b\":-1.0}",
      %FloatPrecision{b: -1.0}
    },
    {
      "float as string",
      "{\"b\":\"-1.0\"}",
      %FloatPrecision{b: -1.0}
    },
    {
      "float as string without decimal",
      "{\"b\":\"-1\"}",
      %FloatPrecision{b: -1.0}
    },
    {
      "string",
      "{\"b\": \"foo\"}",
      %Sub{b: "foo"}
    },
    {
      "bytes",
      "{\"m\":\"AQID\"}",
      %Sub{m: <<1, 2, 3>>}
    },
    {
      "enum as string",
      "{\"r\":\"FOO\"}",
      %Sub{r: :FOO}
    },
    {
      "enum as number",
      "{\"r\":-1}",
      %Sub{r: :NEG}
    },
    {
      "enum as unknown number",
      "{\"r\":42}",
      %Sub{r: 42}
    },
    {
      "int64, sfixed64, uint64, fixed64 as string",
      "{\"c\":\"-1\", \"e\":\"24\", \"l\":\"33\", \"s\":\"67\"}",
      %Sub{c: -1, e: 24, l: 33, s: 67}
    },
    {
      "int64, sfixed64, uint64, fixed64 as numbers",
      "{\"c\":-1, \"e\":24, \"l\":33, \"s\": 67}",
      %Sub{c: -1, e: 24, l: 33, s: 67}
    },
    {
      "nested messasge",
      "{\"msgF\": {\"a\": 1}}",
      %Msg{msg_f: %Sub{a: 1}}
    },
    {
      "oneof set to string",
      "{\"msgN\":\"foo\"}",
      %Msg{msg_m: {:msg_n, "foo"}}
    },
    {
      "oneof set to message",
      "{\"msgO\":{\"a\":1}}",
      %Msg{msg_m: {:msg_o, %Sub{a: 1}}}
    },
    {
      "repeated double as number",
      "{\"i\":[1,-1.12,0.1]}",
      %Sub{i: [1, -1.12, 0.1]}
    },
    {
      "repeated double as string",
      "{\"i\":[\"1\",\"-1.12\",\"0.1\"]}",
      %Sub{i: [1, -1.12, 0.1]}
    },
    {
      "map int32 => string",
      "{\"msgK\":{\"2\":\"2\",\"1\":\"1\"}}",
      %Msg{msg_k: %{1 => "1", 2 => "2"}}
    },
    {
      "map string => double",
      "{\"msgL\":{\"2\":-2.0,\"1\":1.0}}",
      %Msg{msg_l: %{"1" => 1.0, "2" => -2.0}}
    },
    {
      "map sfixed64 => bytes",
      "{\"map1\":{\"2\":\"Ag==\",\"1\":\"AQ==\"}}",
      %Sub{map1: %{1 => <<1>>, 2 => <<2>>}}
    },
    {
      "double +infinity",
      "{\"a\":\"Infinity\"}",
      %FloatPrecision{a: :infinity}
    },
    {
      "double -infinity",
      "{\"a\":\"-Infinity\"}",
      %FloatPrecision{a: :"-infinity"}
    },
    {
      "double nan",
      "{\"a\":\"NaN\"}",
      %FloatPrecision{a: :nan}
    },
    {
      "integer with trailing zeros",
      "{\"optionalInt32\": 100000.000}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_int32: 100_000}
    },
    {
      "integer represented as float value",
      "{\"optionalInt32\": 1e5}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_int32: 100_000}
    },
    {
      "enum alias",
      "{\"optionalAliasedEnum\": \"ALIAS_BAZ\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_aliased_enum: :ALIAS_BAZ}
    },
    {
      "missing padding",
      "{\"optionalBytes\": \"-_\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{optional_bytes: <<251>>}
    },
    {
      "map bool => bool where key is an escaped string",
      "{\"mapBoolBool\": {\"tr\\u0075e\": true}}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{map_bool_bool: %{true => true}}
    },
    {
      "Google.Protobuf.BoolValue",
      "{\"optionalBoolWrapper\": false}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_bool_wrapper: %Google.Protobuf.BoolValue{value: false}
      }
    },
    {
      "Google.Protobuf.BytesValue",
      "{\"optionalBytesWrapper\": \"\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_bytes_wrapper: %Google.Protobuf.BytesValue{value: <<>>}
      }
    },
    {
      "Google.Protobuf.DoubleValue",
      "{\"optionalDoubleWrapper\": 0}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_double_wrapper: %Google.Protobuf.DoubleValue{value: 0.0}
      }
    },
    {
      "Google.Protobuf.FloatValue",
      "{\"optionalFloatWrapper\": \"0\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_float_wrapper: %Google.Protobuf.FloatValue{value: 0.0}
      }
    },
    {
      "Google.Protobuf.Int32Value",
      "{\"optionalInt32Wrapper\": 0}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_int32_wrapper: %Google.Protobuf.Int32Value{value: 0}
      }
    },
    {
      "Google.Protobuf.Int64Value",
      "{\"optionalInt64Wrapper\": 0}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_int64_wrapper: %Google.Protobuf.Int64Value{value: 0}
      }
    },
    {
      "Google.Protobuf.UInt32Value",
      "{\"optionalUint32Wrapper\": 10}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_uint32_wrapper: %Google.Protobuf.UInt32Value{value: 10}
      }
    },
    {
      "Google.Protobuf.UInt64Value",
      "{\"optionalUint64Wrapper\": \"10\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_uint64_wrapper: %Google.Protobuf.UInt64Value{value: 10}
      }
    },
    {
      "Google.Protobuf.StringValue",
      "{\"optionalStringWrapper\": \"foo\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_string_wrapper: %Google.Protobuf.StringValue{value: "foo"}
      }
    },
    {
      "Google.Protobuf.Duration",
      "{\"optionalDuration\": \"-315576000000.999999999s\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_duration: %Google.Protobuf.Duration{
          seconds: -315_576_000_000,
          nanos: -999_999_999
        }
      }
    },
    {
      "Google.Protobuf.Timestamp leap",
      "\"1993-02-10T00:00:00.000Z\"",
      %Google.Protobuf.Timestamp{seconds: 729_302_400, nanos: 0}
    },
    {
      "Google.Protobuf.Timestamp positive offset",
      "\"1970-01-01T08:00:01+08:00\"",
      %Google.Protobuf.Timestamp{seconds: 1, nanos: 0}
    },
    {
      "Google.Protobuf.Timestamp negative offset",
      "\"1969-12-31T16:00:01-08:00\"",
      %Google.Protobuf.Timestamp{seconds: 1, nanos: 0}
    },
    {
      "Google.Protobuf.FieldMask",
      "\"foo,barBaz\"",
      %Google.Protobuf.FieldMask{paths: ["foo", "bar_baz"]}
    },
    {
      "Empty Google.Protobuf.FieldMask",
      "\"\"",
      %Google.Protobuf.FieldMask{paths: []}
    },
    {
      "Google.Protobuf.Value null",
      "{\"optionalValue\": null}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_value: %Google.Protobuf.Value{kind: {:null_value, :NULL_VALUE}}
      }
    },
    {
      "Google.Protobuf.Value double",
      "1.5",
      %Google.Protobuf.Value{kind: {:number_value, 1.5}}
    },
    {
      "Google.Protobuf.Value string",
      "\"foo\"",
      %Google.Protobuf.Value{kind: {:string_value, "foo"}}
    },
    {
      "Google.Protobuf.Value boolean",
      "true",
      %Google.Protobuf.Value{kind: {:bool_value, true}}
    },
    {
      "NullValueInOtherOneofNewFormat",
      "{\"oneofNullValue\": null}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        oneof_field: {:oneof_null_value, :NULL_VALUE}
      }
    },
    {
      "NullValueInOtherOneofOldFormat",
      "{\"oneofNullValue\": \"NULL_VALUE\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        oneof_field: {:oneof_null_value, :NULL_VALUE}
      }
    },
    {
      "OneofFieldNullFirst",
      "{\"oneofUint32\": null, \"oneofString\": \"test\"}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        oneof_field: {:oneof_string, "test"}
      }
    },
    {
      "OneofFieldNullSecond",
      "{\"oneofString\": \"test\", \"oneofUint32\": null}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        oneof_field: {:oneof_string, "test"}
      }
    },
    {
      "All fields accept NULL",
      "{\n
        \"optionalInt32\": null,\n
        \"optionalInt64\": null,\n
        \"optionalUint32\": null,\n
        \"optionalUint64\": null,\n
        \"optionalSint32\": null,\n
        \"optionalSint64\": null,\n
        \"optionalFixed32\": null,\n
        \"optionalFixed64\": null,\n
        \"optionalSfixed32\": null,\n
        \"optionalSfixed64\": null,\n
        \"optionalFloat\": null,\n
        \"optionalDouble\": null,\n
        \"optionalBool\": null,\n
        \"optionalString\": null,\n
        \"optionalBytes\": null,\n
        \"optionalNestedEnum\": null,\n
        \"optionalNestedMessage\": null,\n
        \"repeatedInt32\": null,\n
        \"repeatedInt64\": null,\n
        \"repeatedUint32\": null,\n
        \"repeatedUint64\": null,\n
        \"repeatedSint32\": null,\n
        \"repeatedSint64\": null,\n
        \"repeatedFixed32\": null,\n
        \"repeatedFixed64\": null,\n
        \"repeatedSfixed32\": null,\n
        \"repeatedSfixed64\": null,\n
        \"repeatedFloat\": null,\n
        \"repeatedDouble\": null,\n
        \"repeatedBool\": null,\n
        \"repeatedString\": null,\n
        \"repeatedBytes\": null,\n
        \"repeatedNestedEnum\": null,\n
        \"repeatedNestedMessage\": null,\n
        \"mapInt32Int32\": null,\n
        \"mapBoolBool\": null,\n
        \"mapStringNestedMessage\": null\n
        }",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{}
    },
    {
      "ValueAcceptList",
      "{\"optionalValue\": [0, \"hello\"]}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_value: %Google.Protobuf.Value{
          kind:
            {:list_value,
             %Google.Protobuf.ListValue{
               values: [
                 %Google.Protobuf.Value{kind: {:number_value, 0}},
                 %Google.Protobuf.Value{kind: {:string_value, "hello"}}
               ]
             }}
        }
      }
    },
    {
      "RepeatedListValue",
      "{\"repeatedListValue\": [[\"a\"]]}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        repeated_list_value: [
          %Google.Protobuf.ListValue{values: [%Google.Protobuf.Value{kind: {:string_value, "a"}}]}
        ]
      }
    },
    {
      "ValueAcceptObject",
      "{\"optionalValue\": {\"value\": 1}}",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_value: %Google.Protobuf.Value{
          kind:
            {:struct_value,
             %Google.Protobuf.Struct{
               fields: %{"value" => %Google.Protobuf.Value{kind: {:number_value, 1}}}
             }}
        }
      }
    },
    {
      "Struct",
      "{\n
        \"optionalStruct\": {\n
          \"nullValue\": null,\n
          \"intValue\": 1234,\n
          \"boolValue\": true,\n
          \"doubleValue\": 1234.5678,\n
          \"stringValue\": \"Hello world!\",\n
          \"listValue\": [1234, \"5678\"],\n
          \"objectValue\": {\n
            \"value\": 0\n
          }\n
        }\n
      }",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_struct: %Google.Protobuf.Struct{
          fields: %{
            "nullValue" => %Google.Protobuf.Value{kind: {:null_value, :NULL_VALUE}},
            "intValue" => %Google.Protobuf.Value{kind: {:number_value, 1234}},
            "boolValue" => %Google.Protobuf.Value{kind: {:bool_value, true}},
            "doubleValue" => %Google.Protobuf.Value{kind: {:number_value, 1234.5678}},
            "stringValue" => %Google.Protobuf.Value{kind: {:string_value, "Hello world!"}},
            "listValue" => %Google.Protobuf.Value{
              kind:
                {:list_value,
                 %Google.Protobuf.ListValue{
                   values: [
                     %Google.Protobuf.Value{kind: {:number_value, 1234}},
                     %Google.Protobuf.Value{kind: {:string_value, "5678"}}
                   ]
                 }}
            },
            "objectValue" => %Google.Protobuf.Value{
              kind:
                {:struct_value,
                 %Google.Protobuf.Struct{
                   fields: %{"value" => %Google.Protobuf.Value{kind: {:number_value, 0}}}
                 }}
            }
          }
        }
      }
    }
  ]

  @failure_tests [
    {
      "enum as unknown string",
      "{\"r\":\"WRONG_ENUM_ENTRY\"}",
      Sub
    },
    {
      "invalid float",
      "{\"a\":\"1.0invalid\"}",
      FloatPrecision
    },
    {
      "invalid integer",
      "{\"a\":\"1invalid\"}",
      Sub
    },
    {
      "already existing atom which is not part of the enum",
      "{\"r\":\"scalar\"}",
      Sub
    },
    {
      "map bytes entry value is null",
      "{\"map1\": {\"0\": null}}",
      Sub
    },
    {
      "map int32 entry value is null",
      "{\"mapInt32Int32\": {\"0\": null}}",
      ProtobufTestMessages.Proto3.TestAllTypesProto3
    },
    {
      "float as integer",
      "{\"optionalUint32\": 0.5}",
      ProtobufTestMessages.Proto3.TestAllTypesProto3
    },
    {
      "integer represented as float value too large",
      "{\"optionalInt32\": 4.294967295e9}",
      ProtobufTestMessages.Proto3.TestAllTypesProto3
    },
    {
      "duplicate oneof",
      "{\"oneofUint32\": 1, \"oneofString\": \"test\"}",
      ProtobufTestMessages.Proto3.TestAllTypesProto3
    },
    {
      "missing T in timestamp",
      "\"0001-01-01 00:00:00Z\"",
      Google.Protobuf.Timestamp
    },
    {
      "timestamp too small",
      "\"0000-01-01T00:00:00Z\"",
      Google.Protobuf.Timestamp
    },
    {
      "Empty Google.Protobuf.FieldMask",
      "\"bar_bar\"",
      Google.Protobuf.FieldMask
    }
  ]

  for {description, json, expected} <- @success_tests do
    test "Success: can decode #{description}" do
      json = unquote(json)
      expected = unquote(Macro.escape(expected))

      assert Protox.json_decode!(json, expected.__struct__) == expected
    end
  end

  for {description, json, mod} <- @failure_tests do
    test "Failure: should not decode #{description}" do
      json = unquote(json)
      mod = unquote(mod)

      assert_raise Protox.JsonDecodingError, fn ->
        Protox.json_decode!(json, mod)
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
