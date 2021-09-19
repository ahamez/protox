# A dedicated module to make sure all messages are compiled before Protox.JsonDecodeTest.
defmodule Protox.JsonDecodeTestMessages do
  Code.require_file("./test/support/messages.exs")
end

defmodule Protox.JsonDecodeTest do
  use ExUnit.Case
  use Protox.Float

  @scalar_tests %{
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
    "{\"c\":\"-1\", \"e\":\"-24\", \"l\":\"33\", \"s\":\"67\"}" =>
      {%Sub{c: -1, e: -24, l: 33, s: 67}, "int64, sfixed64, uint64, fixed64 as string"},
    "{\"c\":-1, \"e\":-24, \"l\":33, \"s\": 67}" =>
      {%Sub{c: -1, e: -24, l: 33, s: 67}, "int64, sfixed64, uint64, fixed64 as numbers"},
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
    }
  }

  describe "Scalar types" do
    for {json, {expected, description}} <- @scalar_tests do
      test "Success: can decode #{description}" do
        json = unquote(json)
        expected = unquote(Macro.escape(expected))

        assert Protox.json_decode!(json, expected.__struct__) == expected
      end
    end

    for {value, string} <- [{:infinity, "Infinity"}, {:"-infinity", "-Infinity"}, {:nan, "NaN"}] do
      test "Success: double is #{string}" do
        value = unquote(value)
        string = unquote(string)

        msg = %FloatPrecision{a: value}
        json = "{\"a\":\"#{string}\"}"
        assert Protox.json_decode!(json, FloatPrecision) == msg
      end
    end

    test "Failure: enum as unknown string" do
      assert_raise Protox.JsonDecodingError, fn ->
        Protox.json_decode!("{\"r\":\"WRONG_ENUM_ENTRY\"}", Sub)
      end
    end

    test "Failure: enum as unknown string, when atom already exists but is not part of the enum" do
      _ = :ALREADY_EXISTING_ATOM
      json = "{\"r\":\"ALREADY_EXISTING_ATOM\"}"

      assert_raise Protox.JsonDecodingError, fn ->
        Protox.json_decode!(json, Sub)
      end
    end
  end

  describe "Errors" do
    test "failure: parsing an unknown field raises an exception" do
      json = "{\"this_field_does_not_exist\": 42}"

      assert_raise Protox.JsonDecodingError, fn ->
        Protox.json_decode!(json, Sub)
      end
    end

    test "failure: raise when given a proto2 message" do
      assert_raise Protox.InvalidSyntax, "Syntax should be :proto3, got :proto2", fn ->
        Protox.json_decode!("", Protobuf2)
      end

      assert {:error, %Protox.InvalidSyntax{}} = Protox.json_decode("", Protobuf2)
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
