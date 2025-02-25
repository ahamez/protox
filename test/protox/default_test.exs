defmodule Protox.DefaultTest do
  use ExUnit.Case
  doctest Protox.Default

  alias ProtobufTestMessages.{
    Proto2.TestAllTypesProto2,
    Proto3.ForeignEnum,
    Proto3.TestAllTypesProto3
  }

  test "Protobuf3" do
    assert TestAllTypesProto3.default(:optional_nested_enum) == {:ok, :FOO}
    assert TestAllTypesProto3.default(:map_int32_int32) == {:error, :no_default_value}
    assert TestAllTypesProto3.default(:optional_int32) == {:ok, 0}
    assert TestAllTypesProto3.default(:optional_nested_message) == {:ok, nil}
    assert TestAllTypesProto3.default(:dummy) == {:error, :no_such_field}
  end

  test "Protobuf2" do
    assert TestAllTypesProto2.default(:default_int32) == {:ok, -123_456_789}
    assert TestAllTypesProto2.default(:default_int64) == {:ok, -9_123_456_789_123_456_789}
    assert TestAllTypesProto2.default(:default_uint32) == {:ok, 2_123_456_789}
    assert TestAllTypesProto2.default(:default_uint64) == {:ok, 10_123_456_789_123_456_789}
    assert TestAllTypesProto2.default(:default_sint32) == {:ok, -123_456_789}
    assert TestAllTypesProto2.default(:default_sint64) == {:ok, -9_123_456_789_123_456_789}
    assert TestAllTypesProto2.default(:default_fixed32) == {:ok, 2_123_456_789}
    assert TestAllTypesProto2.default(:default_fixed64) == {:ok, 10_123_456_789_123_456_789}
    assert TestAllTypesProto2.default(:default_sfixed32) == {:ok, -123_456_789}
    assert TestAllTypesProto2.default(:default_sfixed64) == {:ok, -9_123_456_789_123_456_789}
    assert TestAllTypesProto2.default(:default_float) == {:ok, 9.0e9}
    assert TestAllTypesProto2.default(:default_double) == {:ok, 7.0e22}
    assert TestAllTypesProto2.default(:default_bool) == {:ok, true}
    assert TestAllTypesProto2.default(:default_string) == {:ok, "Rosebud"}
    assert TestAllTypesProto2.default(:default_bytes) == {:ok, "joshua"}
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
    assert Protox.Default.default({:enum, ForeignEnum}) == :FOREIGN_FOO
    assert Protox.Default.default({:message, TestAllTypesProto3}) == nil
  end
end
