defmodule Protox.ParseTest do
  use ExUnit.Case

  setup_all do
    data = File.read!("./test/samples/file_descriptor_set.bin")
    %{enums: enums, messages: messages} = Protox.Parse.parse(data)

    {:ok, enums: enums, messages: messages}
  end

  test "Parse FileDescriptorSet, protobuf 3 enums", %{enums: enums} do
    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.ForeignEnum end)
    assert constants == [{0, :FOREIGN_ZERO}, {1, :FOREIGN_ONE}, {1, :FOREIGN_ONE_BIS}]

    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.Proto3.NestedEnum end)
    assert constants == [{0, :FOO}, {2, :BAR}]
  end

  test "Parse FileDescriptorSet, protobuf 3 messages", %{messages: messages} do
    assert syntax(messages, Abc.Def.Proto3) == :proto3
    fs = fields(messages, Abc.Def.Proto3)
    assert field(fs, 1) == {:repeated, :repeated_int32, :packed, :int32}
    assert field(fs, 2) == {:optional, :double, {:scalar, 0}, :double}
    assert field(fs, 3) == {nil, :map_sfixed32_fixed64, :map, {:sfixed32, :fixed64}}
    assert field(fs, 4) == {:optional, :oneof_1_int32, {:oneof, :oneof_1}, :int32}
    assert field(fs, 5) == {:optional, :oneof_1_double, {:oneof, :oneof_1}, :double}

    assert field(fs, 6) ==
             {:optional, :oneof_1_foreign_enum, {:oneof, :oneof_1}, {:enum, Abc.Def.ForeignEnum}}

    assert field(fs, 7) == {:optional, :oneof_1_proto2a, {:oneof, :oneof_1}, {:message, Proto2A}}

    assert field(fs, 8) == {nil, :map_string_proto2a, :map, {:string, {:message, Proto2A}}}

    assert field(fs, 9) == {:optional, :bytes, {:scalar, <<>>}, :bytes}

    assert field(fs, 10) ==
             {nil, :map_int64_nested_enum, :map, {:int64, {:enum, Abc.Def.Proto3.NestedEnum}}}

    assert field(fs, 134) == {:optional, :oneof_2_int32, {:oneof, :oneof_2}, :int32}

    assert field(fs, 135) ==
             {:optional, :oneof_2_nested_enum, {:oneof, :oneof_2},
              {:enum, Abc.Def.Proto3.NestedEnum}}

    assert field(fs, 9999) ==
             {:optional, :nested_enum, {:scalar, :FOO}, {:enum, Abc.Def.Proto3.NestedEnum}}

    assert syntax(messages, Abc.Def.EmptyProto3) == :proto3
    assert [] = fields(messages, Abc.Def.EmptyProto3)
  end

  test "Parse FileDescriptorSet, protobuf 2 enums", %{enums: enums} do
    {_, constants} = Enum.find(enums, fn {name, _} -> name == Proto2A.NestedEnum end)
    assert constants == [{0, :N_ZERO}, {3, :N_THREE}]
  end

  test "Parse FileDescriptorSet, protobuf 2 messages", %{messages: messages} do
    assert syntax(messages, Proto2A.NestedMessage) == :proto2
    fs = fields(messages, Proto2A.NestedMessage)
    assert field(fs, 1) == {:required, :required_string, {:scalar, "foo"}, :string}
    assert field(fs, 2) == {:optional, :optional_float, {:scalar, -1.1}, :float}
    assert field(fs, 3) == {:optional, :optional_fixed64, {:scalar, 32_108}, :fixed64}

    assert syntax(messages, Proto2A) == :proto2
    fs = fields(messages, Proto2A)
    assert field(fs, 1) == {:repeated, :repeated_int32_packed, :packed, :int32}
    assert field(fs, 2) == {:repeated, :repeated_int32_unpacked, :unpacked, :int32}

    assert field(fs, 3) ==
             {:optional, :optional_nested_message, {:scalar, nil},
              {:message, Proto2A.NestedMessage}}

    assert field(fs, 4) ==
             {:repeated, :repeated_nested_enum, :unpacked, {:enum, Proto2A.NestedEnum}}

    assert field(fs, 5) ==
             {:repeated, :repeated_nested_message, :unpacked, {:message, Proto2A.NestedMessage}}

    assert field(fs, 6) == {:optional, :bytes, {:scalar, <<96, 118>>}, :bytes}
    assert field(fs, 126) == {:optional, :extension_int32, {:scalar, 0}, :int32}
    assert field(fs, 199) == {:optional, :extension_double, {:scalar, 42.42}, :double}

    assert syntax(messages, Proto2B) == :proto2
    fs = fields(messages, Proto2B)

    assert field(fs, 1) ==
             {:optional, :optional_proto2a_nested_enum, {:scalar, :N_ZERO},
              {:enum, Proto2A.NestedEnum}}

    assert field(fs, 2) ==
             {:required, :required_proto2a_nested_enum, {:scalar, :N_THREE},
              {:enum, Proto2A.NestedEnum}}
  end

  test "Parse Proto3, packed and unpacked fields", %{messages: messages} do
    fs = fields(messages, Abc.Def.Proto3)

    assert field(fs, 200) == {:repeated, :repeated_int32_packed, :packed, :int32}
    assert field(fs, 201) == {:repeated, :repeated_int32_unpacked, :unpacked, :int32}
  end

  defp field(fields, tag) do
    %Protox.Field{label: label, name: name, kind: kind, type: type} =
      Enum.find(fields, &match?(%Protox.Field{tag: ^tag}, &1))

    {label, name, kind, type}
  end

  def syntax(messages, name) do
    {_, syntax, _} = Enum.find(messages, fn {n, _, _} -> n == name end)
    syntax
  end

  defp fields(messages, name) do
    {_, _, fs} = Enum.find(messages, fn {n, _, _} -> n == name end)

    fs
  end
end
