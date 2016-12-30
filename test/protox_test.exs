defmodule ProtoxTest do
  use ExUnit.Case

  use Protox, """
    syntax = "proto3";
    package fiz;

    message Baz {
    }

    message Foo {
      map<int32, Baz> b = 2;
    }
  """

  use Protox, """
  syntax = "proto3";

  message Buz{
  }
  """


  use Protox, files: [
    "./test/samples/proto2.proto",
    "./test/samples/proto2_extension.proto",
    "./test/samples/proto3.proto",
  ]


  test "symmetric (Sub)" do
    msg = Protox.RandomInit.gen(Sub)
    assert (msg |> Sub.encode() |> :binary.list_to_bin() |> Sub.decode!()) == msg
  end


  test "symmetric (Msg)" do
    msg = Protox.RandomInit.gen(Msg)
    assert (msg |> Msg.encode() |> :binary.list_to_bin() |> Msg.decode!()) == msg
  end


  test "symmetric (Upper)" do
    msg = Protox.RandomInit.gen(Upper)
    assert (msg |> Upper.encode() |> :binary.list_to_bin() |> Upper.decode!()) == msg
  end


  test "from text" do
    assert Fiz.Baz.defs() == %{}
    assert Fiz.Foo.defs() == %{2 => {:b, :map, {:int32, {:message, Fiz.Baz}}}}
    assert Buz.defs() == %{}
  end


  test "from files" do
    assert Proto2A.defs() == %{
      1 => {:repeated_int32_packed, :packed, :int32},
      2 => {:repeated_int32_unpacked, :unpacked, :int32},
      3 => {:optional_nested_message, {:default, nil}, {:message, Proto2A.NestedMessage}},
      4 => {:repeated_nested_enum, :unpacked, {:enum, Proto2A.NestedEnum}},
      5 => {:repeated_nested_message, :unpacked, {:message, Proto2A.NestedMessage}},
      6 => {:bytes, {:default, "`v"}, :bytes},
      126 => {:extension_int32, {:default, nil}, :int32},
      199 => {:extension_double, {:default, 42.42}, :double}
    }

    assert Proto2B.defs() == %{
      1 => {:optional_proto2a_nested_enum, {:default, nil}, {:enum, Proto2A.NestedEnum}},
      2 => {:required_proto2a_nested_enum, {:default, :N_THREE}, {:enum, Proto2A.NestedEnum}}
    }

    assert Abc.Def.Proto3.defs() == %{
      1 => {:repeated_int32, :packed, :int32},
      2 => {:double, {:default, 0}, :double},
      3 => {:map_sfixed32_fixed64, :map, {:sfixed32, :fixed64}},
      4 => {:oneof_1_int32, {:oneof, :oneof_1}, :int32},
      5 => {:oneof_1_double, {:oneof, :oneof_1}, :double},
      6 => {:oneof_1_foreign_enum, {:oneof, :oneof_1}, {:enum, Abc.Def.ForeignEnum}},
      7 => {:oneof_1_proto2a, {:oneof, :oneof_1}, {:message, Proto2A}},
      8 => {:map_string_timestamp, :map, {:string, {:message, Google.Protobuf.Timestamp}}},
      9 => {:bytes, {:default, ""}, :bytes},
      10 => {:map_int64_nested_enum, :map, {:int64, {:enum, Abc.Def.Proto3.NestedEnum}}},
      134 => {:oneof_2_int32, {:oneof, :oneof_2}, :int32},
      135 => {:oneof_2_nested_enum, {:oneof, :oneof_2}, {:enum, Abc.Def.Proto3.NestedEnum}},
      9999 => {:nested_enum, {:default, :FOO}, {:enum, Abc.Def.Proto3.NestedEnum}}
    }
  end

end
