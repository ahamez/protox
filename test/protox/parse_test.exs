defmodule Protox.ParseTest do
  use ExUnit.Case

  setup_all do
    file_descriptor_set_bin_path = Protox.TmpFs.tmp_file_path!(".bin")
    File.rm_rf!(file_descriptor_set_bin_path)

    {"", 0} =
      System.cmd("protoc", [
        "--include_imports",
        "-o",
        file_descriptor_set_bin_path,
        "./test/samples/google/test_messages_proto3.proto",
        "./test/samples/google/test_messages_proto2.proto"
      ])

    data = File.read!(file_descriptor_set_bin_path)
    File.rm_rf!(file_descriptor_set_bin_path)

    {:ok, definition} = Protox.Parse.parse(data)

    {:ok, enums: definition.enums, messages: definition.messages}
  end

  test "Parse FileDescriptorSet, protobuf 3 enums", %{enums: enums} do
    {_, constants} =
      Enum.find(enums, fn {name, _} -> name == ProtobufTestMessages.Proto3.ForeignEnum end)

    assert constants == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]

    {_, constants} =
      Enum.find(enums, fn {name, _} ->
        name == ProtobufTestMessages.Proto3.TestAllTypesProto3.NestedEnum
      end)

    assert constants == [{0, :FOO}, {1, :BAR}, {2, :BAZ}, {-1, :NEG}]
  end

  test "Parse FileDescriptorSet, protobuf 3 messages", %{messages: messages} do
    assert syntax(messages, ProtobufTestMessages.Proto3.TestAllTypesProto3) == :proto3

    fs = fields(messages, ProtobufTestMessages.Proto3.TestAllTypesProto3)

    assert field(fs, 12) == {:optional, :optional_double, {:scalar, 0}, :double}
    assert field(fs, 31) == {:repeated, :repeated_int32, :packed, :int32}
    assert field(fs, 32) == {:repeated, :repeated_int64, :packed, :int64}
    assert field(fs, 64) == {nil, :map_sfixed32_sfixed32, :map, {:sfixed32, :sfixed32}}
    assert field(fs, 75) == {:repeated, :packed_int32, :packed, :int32}
    assert field(fs, 89) == {:repeated, :unpacked_int32, :unpacked, :int32}
    assert field(fs, 111) == {:optional, :oneof_uint32, {:oneof, :oneof_field}, :uint32}

    assert field(fs, 119) ==
             {:optional, :oneof_enum, {:oneof, :oneof_field},
              {:enum, ProtobufTestMessages.Proto3.TestAllTypesProto3.NestedEnum}}

    assert [] = fields(messages, ProtobufTestMessages.Proto3.NullHypothesisProto3)
  end

  test "Parse FileDescriptorSet, protobuf 2 enums", %{enums: enums} do
    {_, constants} =
      Enum.find(enums, fn {name, _} -> name == ProtobufTestMessages.Proto2.ForeignEnumProto2 end)

    assert constants == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]
  end

  test "Parse FileDescriptorSet, protobuf 2 messages", %{messages: messages} do
    assert syntax(messages, ProtobufTestMessages.Proto2.TestAllRequiredTypesProto2) == :proto2

    fs = fields(messages, ProtobufTestMessages.Proto2.TestAllRequiredTypesProto2)

    assert field(fs, 1) == {:required, :required_int32, {:scalar, 0}, :int32}
    assert field(fs, 11) == {:required, :required_float, {:scalar, 0.0}, :float}
    assert field(fs, 15) == {:required, :required_bytes, {:scalar, <<>>}, :bytes}
  end

  defp field(fields, tag) do
    %Protox.Field{label: label, name: name, kind: kind, type: type} =
      Enum.find(fields, &match?(%Protox.Field{tag: ^tag}, &1))

    {label, name, kind, type}
  end

  def syntax(messages, name) do
    msg = Enum.find(messages, fn %Protox.Message{name: n} -> n == name end)

    msg.syntax
  end

  defp fields(messages, name) do
    msg = Enum.find(messages, fn %Protox.Message{name: n} -> n == name end)

    msg.fields
  end
end
