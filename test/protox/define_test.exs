defmodule Protox.DefineTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto3";

      message DefineFoo3 {
        DefineFoo3Enum a = 1;
        map<int32, string> b = 2;
        int32 c = 3;
      }

      enum DefineFoo3Enum {
        FOO = 0;
        BAR = 1;
      }
    """

  use Protox,
    schema: """
      syntax = "proto2";

      message DefineFoo2 {
        required int32 a = 3 [default = 1];
      }
    """

  test "Protobuf3 default values" do
    assert DefineFoo3.default(:a) == {:ok, :FOO}
    assert DefineFoo3.default(:b) == {:error, :no_default_value}
    assert DefineFoo3.default(:c) == {:ok, 0}
    assert DefineFoo3.default(:d) == {:error, :no_such_field}
  end

  test "Protobuf2 custom default values" do
    assert DefineFoo2.default(:a) == {:ok, 1}
  end
end
