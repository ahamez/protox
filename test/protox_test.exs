defmodule ProtoxTest do
  use ExUnit.Case

  doctest Protox

  setup_all do
    {
      :ok,
      seed: Keyword.get(ExUnit.configuration(), :seed)
    }
  end

  test "Can decode using Protox top-level interface" do
    bytes = <<8, 150, 1>>
    assert Protox.decode!(bytes, Sub) == %Sub{a: 150, b: ""}
    assert Protox.decode(bytes, Sub) == {:ok, %Sub{a: 150, b: ""}}
  end

  test "Symmetric float precision" do
    msg = %FloatPrecision{a: 8.73291669056208, b: 0.1}

    decoded = msg |> FloatPrecision.encode!() |> :binary.list_to_bin() |> FloatPrecision.decode!()
    assert decoded.a == msg.a
    assert Float.round(decoded.b, 1) == msg.b
  end

  test "Symmetric (Sub)" do
    msg = Protox.RandomInit.generate_msg(Sub)
    assert msg |> Sub.encode!() |> :binary.list_to_bin() |> Sub.decode!() == msg
  end

  test "Symmetric (Msg)" do
    msg = Protox.RandomInit.generate_msg(Msg)
    assert msg |> Msg.encode!() |> :binary.list_to_bin() |> Msg.decode!() == msg
  end

  test "Symmetric (Upper)" do
    msg = Protox.RandomInit.generate_msg(Upper)
    assert msg |> Upper.encode!() |> :binary.list_to_bin() |> Upper.decode!() == msg
  end

  test "From text" do
    assert FooBarEnum.constants() == [{0, :FOO}, {1, :BAR}]

    assert EncodeExample.fields_defs() == [
             %Protox.Field{
               kind: {:scalar, 0},
               label: :optional,
               name: :a,
               tag: 1,
               type: :int32
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :b,
               tag: 2,
               type: {:int32, :string}
             }
           ]

    assert Empty.fields_defs() == []
  end

  test "From files" do
    assert Proto2A.syntax() == :proto2

    assert Proto2A.fields_defs() == [
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32_packed,
               tag: 1,
               type: :int32
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_int32_unpacked,
               tag: 2,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, nil},
               label: :optional,
               name: :optional_nested_message,
               tag: 3,
               type: {:message, Proto2A.NestedMessage}
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_nested_enum,
               tag: 4,
               type: {:enum, Proto2A.NestedEnum}
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_nested_message,
               tag: 5,
               type: {:message, Proto2A.NestedMessage}
             },
             %Protox.Field{
               kind: {:scalar, "`v"},
               label: :optional,
               name: :bytes,
               tag: 6,
               type: :bytes
             },
             %Protox.Field{
               kind: {:scalar, 0},
               label: :optional,
               name: :extension_int32,
               tag: 126,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, 42.42},
               label: :optional,
               name: :extension_double,
               tag: 199,
               type: :double
             }
           ]

    assert Proto2B.syntax() == :proto2

    assert Proto2B.fields_defs() == [
             %Protox.Field{
               kind: {:scalar, :N_ZERO},
               label: :optional,
               name: :optional_proto2a_nested_enum,
               tag: 1,
               type: {:enum, Proto2A.NestedEnum}
             },
             %Protox.Field{
               kind: {:scalar, :N_THREE},
               label: :required,
               name: :required_proto2a_nested_enum,
               tag: 2,
               type: {:enum, Proto2A.NestedEnum}
             }
           ]

    assert Abc.Def.Proto3.syntax() == :proto3

    assert Abc.Def.Proto3.fields_defs() == [
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32,
               tag: 1,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, 0.0},
               label: :optional,
               name: :double,
               tag: 2,
               type: :double
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_sfixed32_fixed64,
               tag: 3,
               type: {:sfixed32, :fixed64}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_int32,
               tag: 4,
               type: :int32
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_double,
               tag: 5,
               type: :double
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_foreign_enum,
               tag: 6,
               type: {:enum, Abc.Def.MyForeignEnum}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_proto2a,
               tag: 7,
               type: {:message, Proto2A}
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_string_proto2a,
               tag: 8,
               type: {:string, {:message, Proto2A}}
             },
             %Protox.Field{
               kind: {:scalar, ""},
               label: :optional,
               name: :bytes,
               tag: 9,
               type: :bytes
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_int64_nested_enum,
               tag: 10,
               type: {:int64, {:enum, Abc.Def.Proto3.NestedEnum}}
             },
             %Protox.Field{
               kind: {:oneof, :_optional},
               label: :proto3_optional,
               name: :optional,
               tag: 11,
               type: :int32
             },
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_nested_enum,
               tag: 51,
               type: {:enum, Abc.Def.Proto3.NestedEnum}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_2},
               label: :optional,
               name: :oneof_2_int32,
               tag: 134,
               type: :int32
             },
             %Protox.Field{
               kind: {:oneof, :oneof_2},
               label: :optional,
               name: :oneof_2_nested_enum,
               tag: 135,
               type: {:enum, Abc.Def.Proto3.NestedEnum}
             },
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32_packed,
               tag: 200,
               type: :int32
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_int32_unpacked,
               tag: 201,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, :FOO},
               label: :optional,
               name: :nested_enum,
               tag: 9999,
               type: {:enum, Abc.Def.Proto3.NestedEnum}
             }
           ]
  end

  test "from files, with namespace" do
    assert Namespace.Proto2A.syntax() == :proto2

    assert Namespace.Proto2A.fields_defs() == [
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32_packed,
               tag: 1,
               type: :int32
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_int32_unpacked,
               tag: 2,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, nil},
               label: :optional,
               name: :optional_nested_message,
               tag: 3,
               type: {:message, Namespace.Proto2A.NestedMessage}
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_nested_enum,
               tag: 4,
               type: {:enum, Namespace.Proto2A.NestedEnum}
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_nested_message,
               tag: 5,
               type: {:message, Namespace.Proto2A.NestedMessage}
             },
             %Protox.Field{
               kind: {:scalar, "`v"},
               label: :optional,
               name: :bytes,
               tag: 6,
               type: :bytes
             },
             %Protox.Field{
               kind: {:scalar, 0},
               label: :optional,
               name: :extension_int32,
               tag: 126,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, 42.42},
               label: :optional,
               name: :extension_double,
               tag: 199,
               type: :double
             }
           ]

    assert Namespace.Proto2B.syntax() == :proto2

    assert Namespace.Proto2B.fields_defs() == [
             %Protox.Field{
               kind: {:scalar, :N_ZERO},
               label: :optional,
               name: :optional_proto2a_nested_enum,
               tag: 1,
               type: {:enum, Namespace.Proto2A.NestedEnum}
             },
             %Protox.Field{
               kind: {:scalar, :N_THREE},
               label: :required,
               name: :required_proto2a_nested_enum,
               tag: 2,
               type: {:enum, Namespace.Proto2A.NestedEnum}
             }
           ]

    assert Namespace.Abc.Def.Proto3.syntax() == :proto3

    assert Namespace.Abc.Def.Proto3.fields_defs() == [
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32,
               tag: 1,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, 0.0},
               label: :optional,
               name: :double,
               tag: 2,
               type: :double
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_sfixed32_fixed64,
               tag: 3,
               type: {:sfixed32, :fixed64}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_int32,
               tag: 4,
               type: :int32
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_double,
               tag: 5,
               type: :double
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_foreign_enum,
               tag: 6,
               type: {:enum, Namespace.Abc.Def.MyForeignEnum}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_1},
               label: :optional,
               name: :oneof_1_proto2a,
               tag: 7,
               type: {:message, Namespace.Proto2A}
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_string_proto2a,
               tag: 8,
               type: {:string, {:message, Namespace.Proto2A}}
             },
             %Protox.Field{
               kind: {:scalar, ""},
               label: :optional,
               name: :bytes,
               tag: 9,
               type: :bytes
             },
             %Protox.Field{
               kind: :map,
               label: nil,
               name: :map_int64_nested_enum,
               tag: 10,
               type: {:int64, {:enum, Namespace.Abc.Def.Proto3.NestedEnum}}
             },
             %Protox.Field{
               kind: {:oneof, :_optional},
               label: :proto3_optional,
               name: :optional,
               tag: 11,
               type: :int32
             },
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_nested_enum,
               tag: 51,
               type: {:enum, Namespace.Abc.Def.Proto3.NestedEnum}
             },
             %Protox.Field{
               kind: {:oneof, :oneof_2},
               label: :optional,
               name: :oneof_2_int32,
               tag: 134,
               type: :int32
             },
             %Protox.Field{
               kind: {:oneof, :oneof_2},
               label: :optional,
               name: :oneof_2_nested_enum,
               tag: 135,
               type: {:enum, Namespace.Abc.Def.Proto3.NestedEnum}
             },
             %Protox.Field{
               kind: :packed,
               label: :repeated,
               name: :repeated_int32_packed,
               tag: 200,
               type: :int32
             },
             %Protox.Field{
               kind: :unpacked,
               label: :repeated,
               name: :repeated_int32_unpacked,
               tag: 201,
               type: :int32
             },
             %Protox.Field{
               kind: {:scalar, :FOO},
               label: :optional,
               name: :nested_enum,
               tag: 9999,
               type: {:enum, Namespace.Abc.Def.Proto3.NestedEnum}
             }
           ]
  end

  test "Clear unknown fields" do
    assert Proto2A.clear_unknown_fields(%Proto2A{__uf__: [{10, 2, <<104, 101, 121, 33>>}]}) ==
             %Proto2A{}
  end

  test "Don't keep unknown fields when asked not to" do
    bytes = <<8, 42, 25, 246, 40, 92, 143, 194, 53, 69, 64, 136, 241, 4, 83>>
    msg = NoUf.Sub.decode!(bytes)
    assert msg == %NoUf.Sub{a: 42, b: "", z: -42}
    assert Map.get(msg, :__uf__) == nil
  end

  test "Can acess required fields" do
    assert Required.required_fields() == [:a]
    # proto3 messages don't have required fields
    assert Sub.required_fields() == []
  end

  test "Dont generate defs funs when asked not to" do
    refute function_exported?(NoDefsFuns, :defs, 0)
    refute function_exported?(NoDefsFuns, :defs_by_name, 0)
  end

  test "Can export to protoc and read its output (Sub)" do
    msg = Protox.RandomInit.generate_msg(Sub)
    assert msg == msg |> Sub.encode!() |> reencode_with_protoc("Sub") |> Sub.decode!()
  end

  test "Can export to protoc and read its output (Msg)" do
    msg = Protox.RandomInit.generate_msg(Msg)
    assert msg == msg |> Msg.encode!() |> reencode_with_protoc("Msg") |> Msg.decode!()
  end

  test "Can export to protoc and read its output (Upper)" do
    msg = Protox.RandomInit.generate_msg(Upper)
    assert msg == msg |> Upper.encode!() |> reencode_with_protoc("Upper") |> Upper.decode!()
  end

  test "Non Camel_case" do
    msg = Protox.RandomInit.generate_msg(Camel)
    assert msg == msg |> Camel.encode!() |> :binary.list_to_bin() |> Camel.decode!()
  end

  test "Non CamelCase enums" do
    msg = Protox.RandomInit.generate_msg(MsgWithNonCamelEnum)

    assert msg ==
             msg
             |> MsgWithNonCamelEnum.encode!()
             |> :binary.list_to_bin()
             |> MsgWithNonCamelEnum.decode!()

    namespaced_msg = Protox.RandomInit.generate_msg(AnotherNamespace.MsgWithNonCamelEnum)

    assert [
             %Protox.Field{
               name: :snake_case,
               kind: {:scalar, :c},
               type: {:enum, SnakeCase}
             }
           ] = MsgWithNonCamelEnum.fields_defs()

    assert namespaced_msg ==
             namespaced_msg
             |> AnotherNamespace.MsgWithNonCamelEnum.encode!()
             |> :binary.list_to_bin()
             |> AnotherNamespace.MsgWithNonCamelEnum.decode!()
  end

  # -- Helper functions

  defp reencode_with_protoc(encoded, mod) do
    encoded_bin_path = Path.join([Mix.Project.build_path(), "protox_test_sub.bin"])

    File.write!(encoded_bin_path, encoded)

    encoded_txt_cmdline =
      "protoc --decode=#{mod} -I ./test/samples ./test/samples/messages.proto ./test/samples/protobuf2.proto < #{encoded_bin_path}"

    # We use :os.cmd as protoc can only read the content `encoded_bin_path` from stdin.
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    encoded_txt = "#{:os.cmd(String.to_charlist(encoded_txt_cmdline))}"

    encoded_txt_path = Path.join([Mix.Project.build_path(), "protox_test_sub.txt"])

    File.write!(encoded_txt_path, encoded_txt)

    reencoded_bin_path = Path.join([Mix.Project.build_path(), "protoc_test_sub.bin"])

    reencode_bin_cmdline =
      "protoc --encode=#{mod} -I ./test/samples ./test/samples/messages.proto ./test/samples/protobuf2.proto > #{reencoded_bin_path} < #{encoded_txt_path}"

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    :os.cmd(String.to_charlist(reencode_bin_cmdline))

    File.read!(reencoded_bin_path)
  end
end
