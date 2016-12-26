defmodule Protox.ParseTest do
  use ExUnit.Case

  # In protox/test/samples:
  # protoc --include_imports -o ./file_descriptor_set.bin  ./*.proto

  setup_all do
    data = File.read!("./test/samples/file_descriptor_set.bin");

    {:ok, data: data}
  end


  test "Parse FileDescriptorSet", %{data: data} do
    {enums, messages} = Protox.Parse.parse(data)

    # proto3.proto enums
    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.ForeignEnum end)
    assert constants == [{0, :FOREIGN_ZERO}, {1, :FOREIGN_ONE}, {1, :FOREIGN_ONE_BIS}]

    {_, constants} = Enum.find(enums, fn {name, _} -> name == Abc.Def.Proto3.NestedEnum end)
    assert constants == [{0, :FOO}, {2, :BAR}]

    # proto3.proto messages
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


  defp field(fields, tag) do
    Enum.find(fields, &(elem(&1, 0) == tag))
    |> Tuple.delete_at(0)
  end

end
