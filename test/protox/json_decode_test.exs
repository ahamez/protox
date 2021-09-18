defmodule Protox.JsonDecodeTest do
  Code.require_file("./test/messages.exs")

  use ExUnit.Case
  use Protox.Float

  describe "scalar types" do
    test "success: transform null to default value" do
      msg = %Sub{a: 0}
      json = "{\"a\":null}"

      assert Protox.json_decode!(json, Sub) == msg
    end

    test "success: integers" do
      msg = %Sub{
        a: -1
      }

      json = "{\"a\":-1}"

      assert Protox.json_decode!(json, Sub) == msg
    end

    # test "integers" do
    #   msg = %Sub{
    #     a: -1,
    #     c: 10_000,
    #     d: 32,
    #     e: 54,
    #     f: -14,
    #     k: 34,
    #     l: -98,
    #     z: -10
    #   }

    #   # json_decoded =                %{
    #   #            "a" => msg.a,
    #   #            "c" => "#{msg.c}",
    #   #            "d" => msg.d,
    #   #            "e" => "#{msg.e}",
    #   #            "f" => msg.f,
    #   #            "k" => msg.k,
    #   #            "l" => "#{msg.l}",
    #   #            "z" => msg.z
    #   #          }

    # json = "{\"z\":-10,\"l\":\"-98\",\"k\":34,\"f\":-14,\"e\":\"54\",\"d\":32,\"c\":\"10000\",\"a\":-1}"

    # end
  end

  describe "errors" do
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

  describe "JSON libraries" do
    defmodule Jiffy do
      def decode!(input) do
        :jiffy.decode(input, [:return_maps, :use_nil])
      end
    end

    setup do
      {:ok,
       %{json: "{\"a\":null, \"b\":\"foo\", \"c\": 33}", expected: %Sub{a: 0, b: "foo", c: 33}}}
    end

    test "success: jason", %{json: json, expected: expected} do
      assert Protox.json_decode!(json, Sub, json_decoder: Jason) == expected
    end

    test "success: poison", %{json: json, expected: expected} do
      assert Protox.json_decode!(json, Sub, json_decoder: Poison) == expected
    end

    test "success: jiffy", %{json: json, expected: expected} do
      assert Protox.json_decode!(<<json::binary>>, Sub, json_decoder: Protox.JsonDecodeTest.Jiffy) ==
               expected
    end
  end
end
