defmodule Protox.JsonEncodeTestMessages do
  Code.require_file("./test/support/messages.exs")
end

defmodule Protox.JsonEncodeTest do
  # use ExUnit.Case
  use ExUnit.Case, async: false
  use Protox.Float

  @sucess_tests [
    {
      "default values does not output anything (Sub)",
      %Sub{
        a: Protox.Default.default(:int32),
        b: Protox.Default.default(:string),
        c: Protox.Default.default(:int64),
        d: Protox.Default.default(:uint32),
        e: Protox.Default.default(:uint64),
        f: Protox.Default.default(:sint64),
        k: Protox.Default.default(:fixed32),
        l: Protox.Default.default(:sfixed64),
        m: Protox.Default.default(:bytes),
        r: Protox.Default.default({:enum, E}),
        z: Protox.Default.default(:sint32)
      },
      %{}
    },
    {
      "default values does not output anything (Msg)",
      %Msg{
        msg_e: Protox.Default.default(:bool),
        msg_f: Protox.Default.default({:message, Sub}),
        msg_h: Protox.Default.default(:double)
      },
      %{}
    },
    {
      "integers",
      %Sub{a: -1, c: 10_000, d: 32, e: 54, f: -14, k: 34, l: -98, z: -10},
      %{
        "a" => -1,
        "c" => "10000",
        "d" => 32,
        "e" => "54",
        "f" => -14,
        "k" => 34,
        "l" => "-98",
        "z" => -10
      }
    },
    {
      "float infinity",
      %FloatPrecision{a: :infinity, b: :infinity},
      %{"a" => "Infinity", "b" => "Infinity"}
    },
    {
      "float -infinity",
      %FloatPrecision{a: :"-infinity", b: :"-infinity"},
      %{"a" => "-Infinity", "b" => "-Infinity"}
    },
    {
      "float NaN",
      %FloatPrecision{a: :nan, b: :nan},
      %{"a" => "NaN", "b" => "NaN"}
    },
    {
      "string",
      %Sub{b: "foo"},
      %{"b" => "foo"}
    },
    {
      "bytes",
      %Sub{m: <<1, 2, 3>>},
      %{"m" => Base.encode64(<<1, 2, 3>>)}
    },
    {
      "nested empty message",
      %Msg{msg_f: %Sub{}},
      %{"msgF" => %{}}
    },
    {
      "nested message",
      %Msg{msg_f: %Sub{a: 33}},
      %{"msgF" => %{"a" => 33}}
    },
    {
      "enum (existing field)",
      %Sub{r: :BAZ},
      %{"r" => "BAZ"}
    },
    {
      "enum (existing value)",
      %Sub{r: -1},
      %{"r" => "NEG"}
    },
    {
      "enum (unknown value)",
      %Sub{r: 10},
      %{"r" => 10}
    },
    {
      "map int -> string",
      %Msg{msg_k: %{1 => "a", 2 => "b"}},
      %{"msgK" => %{"1" => "a", "2" => "b"}}
    },
    {
      "map int -> enum",
      %Msg{msg_p: %{1 => :FOO, 2 => -1}},
      %{"msgP" => %{"1" => "FOO", "2" => "NEG"}}
    },
    {
      "map string -> message",
      %Upper{msg_map: %{"abc" => %Msg{msg_p: %{1 => :FOO, 2 => -1}}, "def" => %Msg{}}},
      %{"msgMap" => %{"abc" => %{"msgP" => %{"1" => "FOO", "2" => "NEG"}}, "def" => %{}}}
    },
    {
      "array of float",
      %Sub{g: [0, 1], i: [1.0, 0.0, -10], j: [-1, 0, 1]},
      %{"g" => ["0", "1"], "i" => [1.0, 0.0, -10], "j" => [-1, 0, 1]}
    },
    {
      "array of messages",
      %Msg{msg_j: [%Sub{g: [0, 1], i: [1.0, 0.0, -10], j: [-1, 0, 1]}]},
      %{"msgJ" => [%{"g" => ["0", "1"], "i" => [1.0, 0.0, -10], "j" => [-1, 0, 1]}]}
    },
    {
      "oneof string child",
      %Msg{msg_m: {:msg_n, "toto"}},
      %{"msgN" => "toto"}
    },
    {
      "oneof message child",
      %Msg{msg_m: {:msg_o, %Sub{}}},
      %{"msgO" => %{}}
    },
    {
      "Google.Protobuf.Duration",
      %Google.Protobuf.Duration{seconds: 10, nanos: 9_999_999},
      "10.009999999s"
    },
    {
      "Google.Protobuf.Duration 0 fraction digits",
      %Google.Protobuf.Duration{seconds: 1, nanos: 0},
      "1s"
    },
    {
      "Google.Protobuf.Duration 3 fraction digits",
      %Google.Protobuf.Duration{seconds: 1, nanos: 10_000_000},
      "1.010s"
    },
    {
      "Google.Protobuf.Duration 6 fraction digits",
      %Google.Protobuf.Duration{seconds: 1, nanos: 10_000},
      "1.000010s"
    },
    {
      "Google.Protobuf.Duration 9 fraction digits",
      %Google.Protobuf.Duration{seconds: 1, nanos: 10},
      "1.000000010s"
    },
    {
      "Google.Protobuf.Timestamp",
      %Google.Protobuf.Timestamp{seconds: 3000, nanos: 0},
      "1970-01-01T00:50:00.000000Z"
    },
    {
      "Google.Protobuf.FieldMask",
      %Google.Protobuf.FieldMask{paths: ["foo.bar_baz", "foo"]},
      "foo.barBaz,foo"
    },
    {
      "Google.Protobuf.BoolValue",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_bool_wrapper: %Google.Protobuf.BoolValue{value: false}
      },
      %{"optionalBoolWrapper" => false}
    },
    {
      "Google.Protobuf.BytesValue",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_bytes_wrapper: %Google.Protobuf.BytesValue{value: <<>>}
      },
      %{"optionalBytesWrapper" => ""}
    },
    {
      "Google.Protobuf.DoubleValue",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_double_wrapper: %Google.Protobuf.DoubleValue{value: 1.0}
      },
      %{"optionalDoubleWrapper" => 1.0}
    },
    {
      "Google.Protobuf.FloatValue",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_float_wrapper: %Google.Protobuf.FloatValue{value: 1.0}
      },
      %{"optionalFloatWrapper" => 1.0}
    },
    {
      "Google.Protobuf.Int32Value",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_int32_wrapper: %Google.Protobuf.Int32Value{value: 0}
      },
      %{"optionalInt32Wrapper" => 0}
    },
    {
      "Google.Protobuf.Int64Value",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_int64_wrapper: %Google.Protobuf.Int64Value{value: 0}
      },
      %{"optionalInt64Wrapper" => "0"}
    },
    {
      "Google.Protobuf.UInt32Value",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_uint32_wrapper: %Google.Protobuf.UInt32Value{value: 0}
      },
      %{"optionalUint32Wrapper" => 0}
    },
    {
      "Google.Protobuf.UInt64Value",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_uint64_wrapper: %Google.Protobuf.UInt64Value{value: 0}
      },
      %{"optionalUint64Wrapper" => "0"}
    },
    {
      "Google.Protobuf.StringValue",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_string_wrapper: %Google.Protobuf.StringValue{value: "foo"}
      },
      %{"optionalStringWrapper" => "foo"}
    },
    {
      "Google.Protobuf.Duration min value",
      %Google.Protobuf.Duration{seconds: -315_576_000_000, nanos: -999_999_999},
      "-315576000000.999999999s"
    },
    {
      "NullValueInOtherOneofNewFormat",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        oneof_field: {:oneof_null_value, :NULL_VALUE}
      },
      %{"oneofNullValue" => nil}
    },
    {
      "Struct",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_value: %Google.Protobuf.Value{
          kind:
            {:struct_value,
             %Google.Protobuf.Struct{
               fields: %{"value" => %Google.Protobuf.Value{kind: {:number_value, 1}}}
             }}
        }
      },
      %{"optionalValue" => %{"value" => 1}}
    },
    {
      "ListValue",
      %Google.Protobuf.ListValue{values: [%Google.Protobuf.Value{kind: {:number_value, 0}}]},
      [0]
    },
    {
      "NullValue",
      %Google.Protobuf.Value{kind: {:null_value, :NULL_VALUE}},
      nil
    },
    {
      "ListValue inside Value",
      %Google.Protobuf.Value{kind: {:list_value, %Google.Protobuf.ListValue{}}},
      []
    }
  ]

  @failure_tests [
    {
      "duration < minimal duration",
      %Google.Protobuf.Duration{seconds: -315_576_000_000 - 1}
    },
    {
      "duration > maximal duration",
      %Google.Protobuf.Duration{seconds: 315_576_000_000 + 1}
    },
    {
      "duration nanos < minimal nanos",
      %Google.Protobuf.Duration{nanos: -999_999_999 - 1}
    },
    {
      "duration nanos < maximal nanos",
      %Google.Protobuf.Duration{nanos: 999_999_999 + 1}
    },
    {
      "field mask (1)",
      %Google.Protobuf.FieldMask{paths: ["fooBar"]}
    },
    {
      "field mask (2)",
      %Google.Protobuf.FieldMask{paths: ["foo_3_bar"]}
    },
    {
      "field_mask (3)",
      %Google.Protobuf.FieldMask{paths: ["foo__bar"]}
    },
    {
      "invalid string",
      %ProtobufTestMessages.Proto3.TestAllTypesProto3{
        optional_string: "\xFF"
      }
    }
  ]

  for {description, msg, expected} <- @sucess_tests do
    test "Sucess: can encode #{description}" do
      msg = unquote(Macro.escape(msg))
      expected = unquote(Macro.escape(expected))

      assert encode_decode(msg) == expected
    end
  end

  for {description, msg} <- @failure_tests do
    test "Failure: can encode #{description}" do
      msg = unquote(Macro.escape(msg))

      assert_raise Protox.JsonEncodingError, fn ->
        encode!(msg)
      end

      assert {:error, _} = Protox.json_encode(msg)
    end
  end

  describe "Google.Protobuf.Timestamp" do
    test "failure" do
      assert_raise Protox.JsonEncodingError, fn ->
        {:ok, dt, 0} = DateTime.from_iso8601("9999-12-31T23:59:59.999999999Z")
        unix = DateTime.to_unix(dt, :nanosecond) + 1

        msg = %Google.Protobuf.Timestamp{nanos: unix}
        encode!(msg)
      end

      assert_raise Protox.JsonEncodingError, fn ->
        {:ok, dt, 0} = DateTime.from_iso8601("0001-01-01T00:00:00Z")
        unix = DateTime.to_unix(dt, :nanosecond) - 1

        msg = %Google.Protobuf.Timestamp{nanos: unix}
        encode!(msg)
      end
    end
  end

  # -- Private

  defp encode!(msg) do
    msg |> Protox.json_encode!() |> IO.iodata_to_binary()
  end

  defp json_decode!(iodata) do
    Jason.decode!(iodata)
  end

  defp encode_decode(msg) do
    msg |> encode!() |> json_decode!()
  end
end
