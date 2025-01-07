defmodule ProtoxTest do
  use ExUnit.Case

  alias ProtobufTestMessages.Proto3.{ForeignEnum, NullHypothesisProto3, TestAllTypesProto3}
  alias ProtobufTestMessages.Proto2.{TestAllTypesProto2, TestAllRequiredTypesProto2}

  doctest Protox

  setup_all do
    {
      :ok,
      seed: Keyword.get(ExUnit.configuration(), :seed)
    }
  end

  test "Can decode using Protox top-level interface" do
    bytes = <<8, 42>>

    assert Protox.decode!(bytes, TestAllTypesProto3) == %TestAllTypesProto3{optional_int32: 42}

    assert Protox.decode(bytes, TestAllTypesProto3) ==
             {:ok, %TestAllTypesProto3{optional_int32: 42}}
  end

  test "Symmetric float precision" do
    msg = %TestAllTypesProto3{optional_double: 8.73291669056208, optional_float: 0.1}

    decoded =
      msg |> TestAllTypesProto3.encode!() |> :binary.list_to_bin() |> TestAllTypesProto3.decode!()

    assert decoded.optional_double == msg.optional_double
    assert Float.round(decoded.optional_float, 1) == msg.optional_float
  end

  test "Symmetric encoding/decoding of protobuf3 messages" do
    msg = Protox.RandomInit.generate_msg(TestAllTypesProto3)

    assert msg
           |> TestAllTypesProto3.encode!()
           |> :binary.list_to_bin()
           |> TestAllTypesProto3.decode!() == msg
  end

  test "Symmetric encoding/decoding of protobuf2 messages" do
    msg = Protox.RandomInit.generate_msg(TestAllTypesProto2)

    assert msg
           |> TestAllTypesProto2.encode!()
           |> :binary.list_to_bin()
           |> TestAllTypesProto2.decode!() == msg
  end

  test "Enum constants" do
    assert ForeignEnum.constants() == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]
  end

  test "Empty fields" do
    assert NullHypothesisProto3.fields_defs() == []
  end

  test "From text" do
    assert ProtoxExample.fields_defs() == [
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
  end

  test "Can clear unknown fields" do
    assert NullHypothesisProto3.clear_unknown_fields(%NullHypothesisProto3{
             __uf__: [{10, 2, <<104, 101, 121, 33>>}]
           }) ==
             %NullHypothesisProto3{}
  end

  test "Don't keep unknown fields when asked not to" do
    bytes = <<8, 42, 136, 241, 4, 83>>
    msg = NoUf.decode!(bytes)
    assert msg == %NoUf{}
    assert Map.get(msg, :__uf__) == nil
  end

  test "Can access required fields of a protobuf 2 message" do
    assert TestAllRequiredTypesProto2.required_fields() == [
             :required_int32,
             :required_int64,
             :required_uint32,
             :required_uint64,
             :required_sint32,
             :required_sint64,
             :required_fixed32,
             :required_fixed64,
             :required_sfixed32,
             :required_sfixed64,
             :required_float,
             :required_double,
             :required_bool,
             :required_string,
             :required_bytes,
             :required_nested_message,
             :required_foreign_message,
             :required_nested_enum,
             :required_foreign_enum,
             :required_string_piece,
             :required_cord,
             :recursive_message,
             :data,
             :default_int32,
             :default_int64,
             :default_uint32,
             :default_uint64,
             :default_sint32,
             :default_sint64,
             :default_fixed32,
             :default_fixed64,
             :default_sfixed32,
             :default_sfixed64,
             :default_float,
             :default_double,
             :default_bool,
             :default_string,
             :default_bytes
           ]
  end

  test "Protobuf 3 don't have required fields" do
    assert Sub.required_fields() == []
  end

  test "Can export to protoc and read its output for protobuf3 messages" do
    msg = Protox.RandomInit.generate_msg(TestAllTypesProto3)

    assert msg ==
             msg
             |> TestAllTypesProto3.encode!()
             |> reencode_with_protoc("protobuf_test_messages.proto3.TestAllTypesProto3")
             |> TestAllTypesProto3.decode!()
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

    assert [
             %Protox.Field{
               name: :snake_case,
               kind: {:scalar, :c},
               type: {:enum, SnakeCase}
             }
           ] = MsgWithNonCamelEnum.fields_defs()
  end

  # -- Helper functions

  defp reencode_with_protoc(encoded, mod) do
    tmp_dir = Protox.TmpFs.tmp_dir!("protoc_test")

    encoded_bin_path = Path.join([tmp_dir, "protoc_test.bin"])

    File.write!(encoded_bin_path, encoded)

    cmdline = fn op, suffix ->
      path = "./test/samples/google"

      "protoc" <>
        " --#{op}=#{mod}" <>
        " -I #{path}" <>
        " #{path}/test_messages_proto2.proto" <>
        " #{path}/test_messages_proto3.proto" <>
        " #{suffix}"
    end

    encoded_txt_cmdline = cmdline.("decode", "< #{encoded_bin_path}")
    # We use :os.cmd as protoc can only read the content `encoded_bin_path` from stdin.
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    encoded_txt = "#{:os.cmd(String.to_charlist(encoded_txt_cmdline))}"
    encoded_txt_path = Path.join([tmp_dir, "protoc_test.txt"])
    File.write!(encoded_txt_path, encoded_txt)

    reencoded_bin_path = Path.join([tmp_dir, "protoc_test.bin"])
    reencode_bin_cmdline = cmdline.("encode", "> #{reencoded_bin_path} < #{encoded_txt_path}")
    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    :os.cmd(String.to_charlist(reencode_bin_cmdline))
    File.read!(reencoded_bin_path)
  end
end
