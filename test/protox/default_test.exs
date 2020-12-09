defmodule Protox.DefaultTest do
  use ExUnit.Case
  doctest Protox.Default

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

  defmodule E do
    def default(), do: :some_default_value
  end

  test "Protobuf3 enum default value" do
    assert Protox.Default.default({:enum, DefaultFoo3Enum}) == :FOO
  end

  test "Protobuf2 custom default values" do
    assert Protox.Default.default({:enum, DefaultFoo2Enum}) == :FIZ
  end

  test "Default values" do
    assert Protox.Default.default(:bool) == false
    assert Protox.Default.default(:int32) == 0
    assert Protox.Default.default(:uint32) == 0
    assert Protox.Default.default(:int64) == 0
    assert Protox.Default.default(:uint64) == 0
    assert Protox.Default.default(:sint32) == 0
    assert Protox.Default.default(:sint64) == 0
    assert Protox.Default.default(:fixed64) == 0
    assert Protox.Default.default(:sfixed64) == 0
    assert Protox.Default.default(:fixed32) == 0
    assert Protox.Default.default(:sfixed32) == 0
    assert Protox.Default.default(:double) == 0.0
    assert Protox.Default.default(:float) == 0.0
    assert Protox.Default.default(:string) == ""
    assert Protox.Default.default(:bytes) == <<>>
    assert Protox.Default.default({:enum, E}) == :some_default_value
    assert Protox.Default.default({:message, :dummy_module}) == nil
  end
end
