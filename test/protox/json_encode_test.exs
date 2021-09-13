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

      assert msg |> encode!() |> json_decode!() ==
               %{
                 "a" => msg.a,
                 "c" => msg.c,
                 "d" => msg.d,
                 "e" => msg.e,
                 "f" => msg.f,
                 "k" => msg.k,
                 "l" => msg.l,
                 "z" => msg.z
               }
    end

    test "floats" do
      msg = %FloatPrecision{
        a: @positive_infinity_64,
        b: @positive_infinity_32
      }

      assert msg |> encode!() |> json_decode!() ==
               %{
                 "a" => "Infinity",
                 "b" => "Infinity"
               }

      msg = %FloatPrecision{
        a: @negative_infinity_64,
        b: @negative_infinity_32
      }

      assert msg |> encode!() |> json_decode!() ==
               %{
                 "a" => "-Infinity",
                 "b" => "-Infinity"
               }

      msg = %FloatPrecision{
        a: @nan_64,
        b: @nan_32
      }

      assert msg |> encode!() |> json_decode!() ==
               %{
                 "a" => "NaN",
                 "b" => "NaN"
               }
    end

    test "string" do
      msg = %Sub{b: "foo"}

      assert msg |> encode!() |> json_decode!() ==
               %{"b" => msg.b}
    end

    test "bytes" do
      msg = %Sub{m: <<1, 2, 3>>}

      assert msg |> encode!() |> json_decode!() ==
               %{"m" => Base.encode64(msg.m)}
    end

    test "nested empty message" do
      msg = %Msg{msg_f: %Sub{}}

      assert msg |> encode!() |> json_decode!() ==
               %{"msgF" => %{}}
    end

    test "nested message" do
      msg = %Msg{msg_f: %Sub{a: 33}}

      assert msg |> encode!() |> json_decode!() ==
               %{"msgF" => %{"a" => 33}}
    end
  end

  defp encode!(msg) do
    msg |> Protox.JsonEncode.encode!() |> :binary.list_to_bin()
  end

  defp json_decode!(iodata) do
    Jason.decode!(iodata)
  end
end
