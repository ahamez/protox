defmodule Protox.JsonEncodeTest do
  Code.require_file("./test/messages.exs")

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

  defp encode!(msg) do
    msg |> Protox.JsonEncode.encode!() |> IO.iodata_to_binary()
  end

  defp json_decode!(iodata) do
    Jason.decode!(iodata)
  end

  defp encode_decode(msg) do
    msg |> encode!() |> json_decode!()
  end
end
