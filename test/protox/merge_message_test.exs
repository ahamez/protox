defmodule Protox.MergeMessageTest do
  use ExUnit.Case

  doctest Protox.MergeMessage

  alias ProtobufTestMessages.Proto3.{TestAllTypesProto3, TestAllTypesProto3.NestedMessage}

  test "Protobuf 2, replace only set scalar fields" do
    r1 = %Protobuf2Message{a: 0, b: :ONE}
    r2 = %Protobuf2Message{a: nil, b: :TWO}
    r3 = %Protobuf2Message{a: 1, b: nil}

    assert Protox.MergeMessage.merge(r1, r2) == %Protobuf2Message{a: 0, b: :TWO}
    assert Protox.MergeMessage.merge(r1, r3) == %Protobuf2Message{a: 1, b: :ONE}
    assert Protox.MergeMessage.merge(r2, r1) == %Protobuf2Message{a: 0, b: :ONE}
    assert Protox.MergeMessage.merge(r3, r1) == %Protobuf2Message{a: 0, b: :ONE}
  end

  test "Protobuf 2, replace scalar fields" do
    r1 = %Protobuf2Required{a: 3, b: 4}
    r2 = %Protobuf2Required{a: 5, b: 7}

    assert Protox.MergeMessage.merge(r1, r2) == %Protobuf2Required{a: 5, b: 7}
    assert Protox.MergeMessage.merge(r2, r1) == %Protobuf2Required{a: 3, b: 4}
  end

  test "Merge with nil" do
    m = %TestAllTypesProto3{optional_int32: 3}

    assert Protox.MergeMessage.merge(m, nil) == m
    assert Protox.MergeMessage.merge(nil, m) == m
    assert Protox.MergeMessage.merge(nil, nil) == nil
  end

  test "Concatenate repeated fields" do
    m1 = %TestAllTypesProto3{repeated_fixed64: [], repeated_int32: [4, 5, 6]}
    m2 = %TestAllTypesProto3{repeated_fixed64: [10, 20], repeated_int32: [1, 2, 3]}

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             repeated_fixed64: [10, 20],
             repeated_int32: [4, 5, 6, 1, 2, 3]
           }

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             repeated_fixed64: [10, 20],
             repeated_int32: [1, 2, 3, 4, 5, 6]
           }
  end

  test "Overwrite nil messages" do
    m1 = %TestAllTypesProto3{optional_nested_message: nil}
    m2 = %TestAllTypesProto3{optional_nested_message: %NestedMessage{a: 10}}

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             optional_nested_message: %NestedMessage{a: 10}
           }

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             optional_nested_message: %NestedMessage{a: 10}
           }
  end

  test "Overwrite nil oneof" do
    m1 = %TestAllTypesProto3{oneof_field: {:oneof_nested_message, %NestedMessage{a: 42}}}
    m2 = %TestAllTypesProto3{oneof_field: nil}

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             oneof_field: {:oneof_nested_message, %NestedMessage{a: 42}}
           }

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             oneof_field: {:oneof_nested_message, %NestedMessage{a: 42}}
           }
  end

  test "Recursively merge messages in oneof" do
    m1 = %TestAllTypesProto3{oneof_field: {:oneof_nested_message, %NestedMessage{a: 100}}}
    m2 = %TestAllTypesProto3{oneof_field: {:oneof_nested_message, %NestedMessage{a: 200}}}

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             oneof_field: {:oneof_nested_message, %NestedMessage{a: 200}}
           }

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             oneof_field: {:oneof_nested_message, %NestedMessage{a: 100}}
           }
  end

  test "Overwrite non-messages oneof" do
    m1 = %TestAllTypesProto3{oneof_field: {:oneof_enum, :FOO}}
    m2 = %TestAllTypesProto3{oneof_field: {:oneof_enum, :BAR}}

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             oneof_field: {:oneof_enum, :BAR}
           }

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             oneof_field: {:oneof_enum, :FOO}
           }
  end

  test "Merge scalar maps" do
    m1 = %TestAllTypesProto3{map_int32_int32: %{1 => 10, 2 => 20, 100 => 1000}}
    m2 = %TestAllTypesProto3{map_int32_int32: %{1 => 100, 2 => 200, 101 => 10_100}}

    assert Protox.MergeMessage.merge(m1, m2) == %TestAllTypesProto3{
             map_int32_int32: %{1 => 100, 2 => 200, 100 => 1000, 101 => 10_100}
           }

    assert Protox.MergeMessage.merge(m2, m1) == %TestAllTypesProto3{
             map_int32_int32: %{1 => 10, 2 => 20, 100 => 1000, 101 => 10_100}
           }
  end
end
