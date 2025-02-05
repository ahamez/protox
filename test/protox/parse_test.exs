defmodule Protox.ParseTest do
  use ExUnit.Case

  alias Protox.{OneOf, Scalar}

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

    {:ok, enums_schemas: definition.enums_schemas, messages_schemas: definition.messages_schemas}
  end

  test "Parse FileDescriptorSet, protobuf 3 enums", %{enums_schemas: enums} do
    constants = enums[ProtobufTestMessages.Proto3.ForeignEnum]
    assert constants == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]

    constants = enums[ProtobufTestMessages.Proto3.TestAllTypesProto3.NestedEnum]
    assert constants == [{0, :FOO}, {1, :BAR}, {2, :BAZ}, {-1, :NEG}]
  end

  test "Parse FileDescriptorSet, protobuf 3 messages", %{messages_schemas: messages} do
    assert messages[ProtobufTestMessages.Proto3.TestAllTypesProto3].syntax == :proto3

    fs = messages[ProtobufTestMessages.Proto3.TestAllTypesProto3].fields

    assert field(fs, 12) ==
             {:optional, :optional_double, %Scalar{default_value: 0}, :double}

    assert field(fs, 31) == {:repeated, :repeated_int32, :packed, :int32}
    assert field(fs, 32) == {:repeated, :repeated_int64, :packed, :int64}
    assert field(fs, 64) == {nil, :map_sfixed32_sfixed32, :map, {:sfixed32, :sfixed32}}
    assert field(fs, 75) == {:repeated, :packed_int32, :packed, :int32}
    assert field(fs, 89) == {:repeated, :unpacked_int32, :unpacked, :int32}
    assert field(fs, 111) == {:optional, :oneof_uint32, %OneOf{parent: :oneof_field}, :uint32}

    assert field(fs, 119) ==
             {:optional, :oneof_enum, %OneOf{parent: :oneof_field},
              {:enum, ProtobufTestMessages.Proto3.TestAllTypesProto3.NestedEnum}}

    assert %{} = messages[ProtobufTestMessages.Proto3.NullHypothesisProto3].fields
  end

  test "Parse FileDescriptorSet, protobuf 2 enums", %{enums_schemas: enums} do
    constants = enums[ProtobufTestMessages.Proto2.ForeignEnumProto2]
    assert constants == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]
  end

  test "Parse FileDescriptorSet, protobuf 2 messages", %{messages_schemas: messages} do
    assert messages[ProtobufTestMessages.Proto2.TestAllRequiredTypesProto2].syntax == :proto2

    fs = messages[ProtobufTestMessages.Proto2.TestAllRequiredTypesProto2].fields

    assert field(fs, 1) == {:required, :required_int32, %Scalar{default_value: 0}, :int32}

    assert field(fs, 11) ==
             {:required, :required_float, %Scalar{default_value: 0.0}, :float}

    assert field(fs, 15) ==
             {:required, :required_bytes, %Scalar{default_value: <<>>}, :bytes}
  end

  defp field(fields, tag) do
    field =
      fields
      |> Map.values()
      |> Enum.find(&(&1.tag == tag))

    %Protox.Field{label: label, name: name, kind: kind, type: type} = field

    {label, name, kind, type}
  end
end
