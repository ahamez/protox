defmodule ExampleTest do
  use ExUnit.Case

  # This example shows how most protobuf types are translated into Elixir code.
  use Protox,
    schema: """
      syntax = "proto3";

      enum FooOrBar {
        FOO = 0;
        BAR = 1;
      }

      message SubMsg {
        int32 a = 1;
        string b = 2;
        int64 c = 3;
        double d = 4;
        bytes e = 5;
        bool f = 6;
        FooOrBar g = 7;
        repeated int32 h = 8;
        map<string, int32> i = 9;
      }

      message Envelope {
        oneof envelope {
          string str = 1;
          SubMsg sub_msg = 2;
        }
      }
    """

  test "Example" do
    # Here the oneof is set to a SubMsg.
    sub_msg = %Envelope{
      envelope:
        {:sub_msg,
         %SubMsg{
           a: 1,
           b: "foo",
           c: 42,
           d: 3.3,
           e: <<1, 2, 3>>,
           f: true,
           g: :FOO,
           h: [1, 2, 3],
           i: %{"foo" => 42, "bar" => 33}
         }}
    }

    # Here the oneof is set to a string.
    str = %Envelope{
      envelope: {:str, "some string"}
    }

    encoded_sub_msg = sub_msg |> Envelope.encode!() |> :binary.list_to_bin()
    assert Envelope.decode!(encoded_sub_msg) == sub_msg

    encoded_str = str |> Envelope.encode!() |> :binary.list_to_bin()
    assert Envelope.decode!(encoded_str) == str
  end
end
