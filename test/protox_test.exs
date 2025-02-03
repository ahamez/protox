defmodule ProtoxTest do
  use ExUnit.Case

  alias Protox.Scalar
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
      msg
      |> TestAllTypesProto3.encode!()
      |> elem(0)
      |> :binary.list_to_bin()
      |> TestAllTypesProto3.decode!()

    assert decoded.optional_double == msg.optional_double
    assert Float.round(decoded.optional_float, 1) == msg.optional_float
  end

  test "Symmetric encoding/decoding of protobuf3 messages" do
    msg = Protox.RandomInit.generate_msg(TestAllTypesProto3)

    assert msg
           |> TestAllTypesProto3.encode!()
           |> elem(0)
           |> :binary.list_to_bin()
           |> TestAllTypesProto3.decode!() == msg
  end

  test "Symmetric encoding/decoding of protobuf2 messages" do
    msg = Protox.RandomInit.generate_msg(TestAllTypesProto2)

    assert msg
           |> TestAllTypesProto2.encode!()
           |> elem(0)
           |> :binary.list_to_bin()
           |> TestAllTypesProto2.decode!() == msg
  end

  test "Enum constants" do
    assert ForeignEnum.constants() == [{0, :FOREIGN_FOO}, {1, :FOREIGN_BAR}, {2, :FOREIGN_BAZ}]
  end

  test "Empty fields" do
    assert NullHypothesisProto3.schema().fields == %{}
  end

  test "From text" do
    assert ProtoxExample.schema().fields == %{
             a: %Protox.Field{
               kind: %Scalar{default_value: 0},
               label: :optional,
               name: :a,
               tag: 1,
               type: :int32
             },
             b: %Protox.Field{
               kind: :map,
               label: nil,
               name: :b,
               tag: 2,
               type: {:int32, :string}
             }
           }
  end

  test "Can clear unknown fields" do
    assert NullHypothesisProto3.clear_unknown_fields(%NullHypothesisProto3{
             __uf__: [{10, 2, <<104, 101, 121, 33>>}]
           }) ==
             %NullHypothesisProto3{}
  end

  test "Can access required fields of a protobuf 2 message" do
    required_fields =
      TestAllRequiredTypesProto2.schema().fields
      |> Enum.flat_map(fn
        {name, %Protox.Field{label: :required}} -> [name]
        _ -> []
      end)
      |> Enum.sort()

    assert required_fields == [
             :data,
             :default_bool,
             :default_bytes,
             :default_double,
             :default_fixed32,
             :default_fixed64,
             :default_float,
             :default_int32,
             :default_int64,
             :default_sfixed32,
             :default_sfixed64,
             :default_sint32,
             :default_sint64,
             :default_string,
             :default_uint32,
             :default_uint64,
             :recursive_message,
             :required_bool,
             :required_bytes,
             :required_cord,
             :required_double,
             :required_fixed32,
             :required_fixed64,
             :required_float,
             :required_foreign_enum,
             :required_foreign_message,
             :required_int32,
             :required_int64,
             :required_nested_enum,
             :required_nested_message,
             :required_sfixed32,
             :required_sfixed64,
             :required_sint32,
             :required_sint64,
             :required_string,
             :required_string_piece,
             :required_uint32,
             :required_uint64
           ]
  end

  test "Protobuf 3 don't have required fields" do
    required_fields =
      for {name, %Protox.Field{label: :required}} <- TestAllTypesProto3.schema().fields, do: name

    assert required_fields == []
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
    assert msg == msg |> Camel.encode!() |> elem(0) |> :binary.list_to_bin() |> Camel.decode!()
  end

  test "Non CamelCase enums" do
    msg = Protox.RandomInit.generate_msg(MsgWithNonCamelEnum)

    assert msg ==
             msg
             |> MsgWithNonCamelEnum.encode!()
             |> elem(0)
             |> :binary.list_to_bin()
             |> MsgWithNonCamelEnum.decode!()

    assert %{
             snake_case: %Protox.Field{
               name: :snake_case,
               kind: %Scalar{default_value: :c},
               type: {:enum, SnakeCase}
             }
           } = MsgWithNonCamelEnum.schema().fields
  end

  # -- Helper functions

  defp reencode_with_protoc({encoded, _size}, mod) do
    tmp_dir = Protox.TmpFs.tmp_dir!("protoc_test")

    encoded = :binary.list_to_bin(encoded)

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
