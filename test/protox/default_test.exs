defmodule Protox.DefaultTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto3";

      enum DefaultFoo3Enum {
        FOO = 0;
        BAR = 1;
      }
    """

  use Protox,
    schema: """
      syntax = "proto2";

      enum DefaultFoo2Enum {
        FIZ = 0;
        BUZ = 1;
      }
    """

  test "Protobuf3 enum default value" do
    assert Protox.Default.default({:enum, DefaultFoo3Enum}) == :FOO
  end

  test "Protobuf2 custom default values" do
    assert Protox.Default.default({:enum, DefaultFoo2Enum}) == :FIZ
  end
end
