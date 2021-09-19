defmodule Protox.JsonEncodeTest do
  Code.require_file("./test/support/messages.exs")

  use ExUnit.Case
  use Protox.Float

  describe "scalar types" do
    test "default values does not output anything" do
      msg = %Sub{
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
      }

      assert encode!(msg) == "{}"

      msg = %Msg{
        msg_e: Protox.Default.default(:bool),
        msg_f: Protox.Default.default({:message, Sub}),
        msg_h: Protox.Default.default(:double)
      }

      assert encode!(msg) == "{}"
    end

    test "integers" do
      msg = %Sub{
        a: -1,
        c: 10_000,
        d: 32,
        e: 54,
        f: -14,
        k: 34,
        l: -98,
        z: -10
      }

      assert encode_decode(msg) ==
               %{
                 "a" => msg.a,
                 "c" => "#{msg.c}",
                 "d" => msg.d,
                 "e" => "#{msg.e}",
                 "f" => msg.f,
                 "k" => msg.k,
                 "l" => "#{msg.l}",
                 "z" => msg.z
               }
    end

    test "floats" do
      msg = %FloatPrecision{a: :infinity, b: :infinity}
      assert encode_decode(msg) == %{"a" => "Infinity", "b" => "Infinity"}

      msg = %FloatPrecision{a: :"-infinity", b: :"-infinity"}
      assert encode_decode(msg) == %{"a" => "-Infinity", "b" => "-Infinity"}

      msg = %FloatPrecision{a: :nan, b: :nan}
      assert encode_decode(msg) == %{"a" => "NaN", "b" => "NaN"}
    end

    test "string" do
      msg = %Sub{b: "foo"}
      assert encode_decode(msg) == %{"b" => msg.b}
    end

    test "bytes" do
      msg = %Sub{m: <<1, 2, 3>>}
      assert encode_decode(msg) == %{"m" => Base.encode64(msg.m)}
    end

    test "nested empty message" do
      msg = %Msg{msg_f: %Sub{}}
      assert encode_decode(msg) == %{"msgF" => %{}}
    end

    test "nested message" do
      msg = %Msg{msg_f: %Sub{a: 33}}
      assert encode_decode(msg) == %{"msgF" => %{"a" => 33}}
    end

    test "enum" do
      msg1 = %Sub{r: :BAZ}
      assert encode_decode(msg1) == %{"r" => "BAZ"}

      msg2 = %Sub{r: -1}
      assert encode_decode(msg2) == %{"r" => "NEG"}

      msg3 = %Sub{r: 10}
      assert encode_decode(msg3) == %{"r" => 10}
    end
  end

  describe "repeated" do
    test "map" do
      msg1 = %Msg{msg_k: %{1 => "a", 2 => "b"}}
      assert encode_decode(msg1) == %{"msgK" => %{"1" => "a", "2" => "b"}}

      msg2 = %Msg{msg_p: %{1 => :FOO, 2 => -1}}
      assert encode_decode(msg2) == %{"msgP" => %{"1" => "FOO", "2" => "NEG"}}

      msg3 = %Upper{msg_map: %{"abc" => %Msg{msg_p: %{1 => :FOO, 2 => -1}}, "def" => %Msg{}}}

      assert encode_decode(msg3) == %{
               "msgMap" => %{"abc" => %{"msgP" => %{"1" => "FOO", "2" => "NEG"}}, "def" => %{}}
             }
    end

    test "array" do
      msg1 = %Sub{g: [0, 1], i: [1.0, 0.0, -10], j: [-1, 0, 1]}

      assert encode_decode(msg1) == %{
               "g" => ["0", "1"],
               "i" => [1.0, 0.0, -10],
               "j" => [-1, 0, 1]
             }

      msg2 = %Msg{msg_j: [msg1]}

      assert encode_decode(msg2) == %{
               "msgJ" => [%{"g" => ["0", "1"], "i" => [1.0, 0.0, -10], "j" => [-1, 0, 1]}]
             }
    end
  end

  describe "oneof" do
    test "string" do
      msg = %Msg{msg_m: {:msg_n, "toto"}}
      assert encode_decode(msg) == %{"msgN" => "toto"}
    end

    test "message" do
      msg = %Msg{msg_m: {:msg_o, %Sub{}}}
      assert encode_decode(msg) == %{"msgO" => %{}}
    end
  end

  describe "Google.Protobuf.Duration" do
    test "success" do
      msg = %Google.Protobuf.Duration{seconds: 10, nanos: 9_999_999}
      assert encode_decode(msg) == "10.010000s"
    end

    test "failure: duration < minimal duration" do
      msg = %Google.Protobuf.Duration{seconds: -315_576_000_000 - 1}

      assert_raise Protox.JsonEncodingError, fn ->
        encode!(msg)
      end

      assert {:error, _} = Protox.json_encode(msg)
    end

    test "failure: duration > maximal duration" do
      msg = %Google.Protobuf.Duration{seconds: 315_576_000_000 + 1}

      assert_raise Protox.JsonEncodingError, fn ->
        encode!(msg)
      end

      assert {:error, _} = Protox.json_encode(msg)
    end

    test "failure: duration nanos < minimal nanos" do
      msg = %Google.Protobuf.Duration{nanos: -999_999_999 - 1}

      assert_raise Protox.JsonEncodingError, fn ->
        encode!(msg)
      end

      assert {:error, _} = Protox.json_encode(msg)
    end

    test "failure: duration nanos < maximal nanos" do
      msg = %Google.Protobuf.Duration{nanos: 999_999_999 + 1}

      assert_raise Protox.JsonEncodingError, fn ->
        encode!(msg)
      end

      assert {:error, _} = Protox.json_encode(msg)
    end
  end

  describe "Google.Protobuf.Timestamp" do
    test "success" do
      msg = %Google.Protobuf.Timestamp{seconds: 3000, nanos: 0}
      assert encode_decode(msg) == "1970-01-01T00:50:00.000000Z"
    end

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

  describe "Google.Protobuf.FieldMask" do
    test "success" do
      msg = %Google.Protobuf.FieldMask{paths: ["foo.bar_baz", "foo"]}
      assert encode_decode(msg) == "foo.barBaz,foo"
    end

    test "failure" do
      assert_raise Protox.JsonEncodingError, fn ->
        msg = %Google.Protobuf.FieldMask{paths: ["fooBar"]}
        encode!(msg)
      end

      assert_raise Protox.JsonEncodingError, fn ->
        msg = %Google.Protobuf.FieldMask{paths: ["foo_3_bar"]}
        encode!(msg)
      end

      assert_raise Protox.JsonEncodingError, fn ->
        msg = %Google.Protobuf.FieldMask{paths: ["foo__bar"]}
        encode!(msg)
      end
    end
  end

  describe "JSON libraries" do
    test "Jason" do
      msg = %Msg{msg_k: %{1 => "a", 2 => "b"}}
      json = Protox.json_encode!(msg, json_encoder: Jason)

      assert json == [
               "{",
               ["\"msgK\"", ":", ["{", "\"2\"", ":", "\"b\"", ",", "\"1\"", ":", "\"a\"", "}"]],
               "}"
             ]
    end

    test "Poison" do
      msg = %Msg{msg_k: %{1 => "a", 2 => "b"}}
      json = Protox.json_encode!(msg, json_encoder: Poison)

      assert json == [
               "{",
               ["\"msgK\"", ":", ["{", "\"2\"", ":", "\"b\"", ",", "\"1\"", ":", "\"a\"", "}"]],
               "}"
             ]
    end

    test "jiffy" do
      defmodule Jiffy do
        defdelegate encode!(msg), to: :jiffy, as: :encode
      end

      msg = %Msg{msg_k: %{1 => "a", 2 => "b"}}
      json = Protox.json_encode!(msg, json_encoder: Protox.JsonEncodeTest.Jiffy)

      assert json == [
               "{",
               ["\"msgK\"", ":", ["{", "\"2\"", ":", "\"b\"", ",", "\"1\"", ":", "\"a\"", "}"]],
               "}"
             ]
    end
  end

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
