defmodule Protox.ParseTest do
  use ExUnit.Case

  # In protox/test/samples:
  # protoc --include_imports -o ./file_descriptor_set.bin  ./*.proto

  setup_all do
    data = File.read!("./test/samples/file_descriptor_set.bin");
    {enums, messages} = Protox.Parse.parse(data)

    {:ok, enums: enums, messages: messages}
  end


  test "Parse FileDescriptorSet, protobuf 3 enums",
  %{enums: enums}
  do
    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.ForeignEnum end)
    assert constants == [{0, :FOREIGN_ZERO}, {1, :FOREIGN_ONE}, {1, :FOREIGN_ONE_BIS}]

    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.Proto3.NestedEnum end)
    assert constants == [{0, :FOO}, {2, :BAR}]
  end


  test "Parse FileDescriptorSet, protobuf 3 messages",
  %{messages: messages}
  do
    {_, fs} = Enum.find(messages, fn {name, _} -> name == Abc.Def.Proto3 end)
    assert field(fs, 1) == {:repeated, :repeated_int32, :packed, :int32}
    assert field(fs, 2) == {:optional, :double, {:default, 0}, :double}
    assert field(fs, 3) == {nil, :map_sfixed32_fixed64, :map, {:sfixed32, :fixed64}}
    assert field(fs, 4) == {:optional, :oneof_1_int32, {:oneof, :oneof_1}, :int32}
    assert field(fs, 5) == {:optional, :oneof_1_double, {:oneof, :oneof_1}, :double}
    assert field(fs, 6) == {:optional, :oneof_1_foreign_enum, {:oneof, :oneof_1}, {:enum, Abc.Def.ForeignEnum}}
    assert field(fs, 7) == {:optional, :oneof_1_proto2a, {:oneof, :oneof_1}, {:message, Proto2A}}
    assert field(fs, 8) == {nil, :map_string_timestamp, :map, {:string, {:message, Google.Protobuf.Timestamp}}}
    assert field(fs, 134) == {:optional, :oneof_2_int32, {:oneof, :oneof_2}, :int32}
    assert field(fs, 135) == {:optional, :oneof_2_nested_enum, {:oneof, :oneof_2}, {:enum, Abc.Def.Proto3.NestedEnum}}
    assert field(fs, 9999) == {:optional, :nested_enum, {:default, :FOO}, {:enum, Abc.Def.Proto3.NestedEnum}}
  end


  test "Parse FileDescriptorSet, protobuf 2 enums",
  %{enums: enums}
  do
    {_, constants} = Enum.find(enums, fn {name, _} -> name == E end)
    assert constants == [{1, :E_ONE}, {2, :E_TWO}]

    {_, constants} = Enum.find(enums, fn {name, _} -> name == Proto2A.NestedEnum end)
    assert constants == [{0, :N_ZERO}, {3, :N_THREE}]
  end


  test "Parse FileDescriptorSet, protobuf 2 messages",
  %{messages: messages}
  do
    {_, fs} = Enum.find(messages, fn {name, _} -> name == Proto2A.NestedMessage end)
    assert field(fs, 1) == {:required, :required_string, {:default, "foo"}, :string}
    assert field(fs, 2) == {:optional, :optional_float, {:default, -1.1}, :float}
    assert field(fs, 3) == {:optional, :optional_fixed64, {:default, 32108}, :fixed64}

    {_, fs} = Enum.find(messages, fn {name, _} -> name == Proto2A end)
    assert field(fs, 1) == {:repeated, :repeated_int32_packed, :packed, :int32}
    assert field(fs, 2) == {:repeated, :repeated_int32_unpacked, :unpacked, :int32}
    assert field(fs, 3) == {:optional, :optional_nested_message, {:default, nil}, {:message, Proto2A.NestedMessage}}
    assert field(fs, 4) == {:repeated, :repeated_nested_enum, :unpacked, {:enum, Proto2A.NestedEnum}}
    assert field(fs, 5) == {:repeated, :repeated_nested_message, :unpacked, {:message, Proto2A.NestedMessage}}
    assert field(fs, 126) == {:optional, :extension_int32, {:default, nil}, :int32}
    assert field(fs, 199) == {:optional, :extension_double, {:default, 42.42}, :double}

    {_, fs} = Enum.find(messages, fn {name, _} -> name == Proto2B end)
    assert field(fs, 1) == {:optional, :optional_proto2a_nested_enum, {:default, nil}, {:enum, Proto2A.NestedEnum}}
    assert field(fs, 2) == {:required, :required_proto2a_nested_enum, {:default, :N_THREE}, {:enum, Proto2A.NestedEnum}}
  end


  defp field(fields, tag) do
    Enum.find(fields, &(elem(&1, 0) == tag))
    |> Tuple.delete_at(0)
  end

end
