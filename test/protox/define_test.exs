defmodule Protox.DefineTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto3";

      message DefineEmpty3 {
      }

      message DefineFoo3 {
        DefineFoo3Enum a = 1;
        map<int32, string> b = 2;
        int32 c = 3;
        DefineEmpty3 d = 4;
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
        required int32 a = 1 [default = 1];
        required int32 b = 2;
        optional DefineFoo2Enum c = 3;
        optional bool d = 4 [default = true];
        optional bool e = 5 [default = false];
        optional DefineFoo2Enum f = 6 [default = BAR];
      }

      enum DefineFoo2Enum {
        FOO = 1;
        BAR = 2;
      }
    """

  test "Protobuf3 default values" do
    assert DefineFoo3.default(:a) == {:ok, :FOO}
    assert DefineFoo3.default(:b) == {:error, :no_default_value}
    assert DefineFoo3.default(:c) == {:ok, 0}
    assert DefineFoo3.default(:d) == {:ok, nil}
    assert DefineFoo3.default(:e) == {:error, :no_such_field}
  end

  test "Protobuf2 custom default values" do
    assert DefineFoo2.default(:a) == {:ok, 1}
    assert DefineFoo2.default(:b) == {:ok, 0}
    assert DefineFoo2.default(:c) == {:ok, :FOO}
    assert DefineFoo2.default(:d) == {:ok, true}
    assert DefineFoo2.default(:e) == {:ok, false}
    assert DefineFoo2.default(:f) == {:ok, :BAR}
  end
end
