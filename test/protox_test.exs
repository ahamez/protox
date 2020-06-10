defmodule ProtoxTest do
  use ExUnit.Case

  use Protox,
    schema: """
      syntax = "proto3";
      package fiz;

      message Baz {
      }

      message Foo {
        Enum a = 1;
        map<int32, Baz> b = 2;
      }

      enum Enum {
        FOO = 0;
        BAR = 1;
      }
    """,
    namespace: Namespace

  use Protox,
    schema: """
    syntax = "proto3";

    message Buz{
    }
    """

  use Protox,
    schema: """
    syntax = "proto3";

    enum Enum {
        FOO = 0;
        BAR = 1;
      }
    """,
    namespace: Namespace

  use Protox,
    files: [
      Path.join(__DIR__, "test/samples/proto2.proto"),
      "./test/samples/proto2_extension.proto",
      "./test/samples/proto3.proto"
    ]

  use Protox,
    files: [
      "./test/samples/proto2.proto",
      "./test/samples/proto2_extension.proto",
      "./test/samples/proto3.proto"
    ],
    namespace: Namespace

  use Protox,
    files: [
      "./test/samples/prefix/foo.proto",
      "./test/samples/prefix/bar/bar.proto"
    ],
    namespace: TestPrefix,
    path: Path.join(__DIR__, "test/samples")

  use Protox,
    files: [
      "./test/samples/prefix/baz.proto"
    ],
    namespace: TestPrefix,
    path: "./test/samples"

  use Protox,
    schema: """
    syntax = "proto3";

    message non_camel {
      int32 x = 1;
    }

    message Camel {
      non_camel x = 1;
    }
    """

  setup_all do
    {
      :ok,
      seed: Keyword.get(ExUnit.configuration(), :seed)
    }
  end

  test "symmetric float precision" do
    msg = %FloatPrecision{
      a: 8.73291669056208,
      b: 0.1
    }

    decoded = msg |> FloatPrecision.encode!() |> :binary.list_to_bin() |> FloatPrecision.decode!()
    assert decoded.a == msg.a
    assert Float.round(decoded.b, 1) == msg.b
  end

  test "symmetric (Sub)" do
    msg = Protox.RandomInit.generate_msg(Sub)
    assert msg |> Sub.encode!() |> :binary.list_to_bin() |> Sub.decode!() == msg
  end

  test "symmetric (Msg)" do
    msg = Protox.RandomInit.generate_msg(Msg)
    assert msg |> Msg.encode!() |> :binary.list_to_bin() |> Msg.decode!() == msg
  end

  test "symmetric (Upper)" do
    msg = Protox.RandomInit.generate_msg(Upper)
    assert msg |> Upper.encode!() |> :binary.list_to_bin() |> Upper.decode!() == msg
  end

  test "from text" do
    assert Namespace.Fiz.Enum.constants() == [{0, :FOO}, {1, :BAR}]
    assert Namespace.Fiz.Baz.defs() == %{}

    assert Namespace.Fiz.Foo.defs() == %{
             1 => {:a, {:default, :FOO}, {:enum, Namespace.Fiz.Enum}},
             2 => {:b, :map, {:int32, {:message, Namespace.Fiz.Baz}}}
           }

    assert Buz.defs() == %{}
    assert Namespace.Enum.constants() == [{0, :FOO}, {1, :BAR}]
  end

  test "from files" do
    assert Proto2A.syntax() == :proto2

    assert Proto2A.defs() == %{
             1 => {:repeated_int32_packed, :packed, :int32},
             2 => {:repeated_int32_unpacked, :unpacked, :int32},
             3 => {:optional_nested_message, {:default, nil}, {:message, Proto2A.NestedMessage}},
             4 => {:repeated_nested_enum, :unpacked, {:enum, Proto2A.NestedEnum}},
             5 => {:repeated_nested_message, :unpacked, {:message, Proto2A.NestedMessage}},
             6 => {:bytes, {:default, "`v"}, :bytes},
             126 => {:extension_int32, {:default, 0}, :int32},
             199 => {:extension_double, {:default, 42.42}, :double}
           }

    assert Proto2B.syntax() == :proto2

    assert Proto2B.defs() == %{
             1 =>
               {:optional_proto2a_nested_enum, {:default, :N_ZERO}, {:enum, Proto2A.NestedEnum}},
             2 =>
               {:required_proto2a_nested_enum, {:default, :N_THREE}, {:enum, Proto2A.NestedEnum}}
           }

    assert Abc.Def.Proto3.syntax() == :proto3

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
             135 =>
               {:oneof_2_nested_enum, {:oneof, :oneof_2}, {:enum, Abc.Def.Proto3.NestedEnum}},
             9999 => {:nested_enum, {:default, :FOO}, {:enum, Abc.Def.Proto3.NestedEnum}}
           }
  end

  test "from files, with namespace" do
    assert Namespace.Proto2A.syntax() == :proto2

    assert Namespace.Proto2A.defs() == %{
             1 => {:repeated_int32_packed, :packed, :int32},
             2 => {:repeated_int32_unpacked, :unpacked, :int32},
             3 =>
               {:optional_nested_message, {:default, nil},
                {:message, Namespace.Proto2A.NestedMessage}},
             4 => {:repeated_nested_enum, :unpacked, {:enum, Namespace.Proto2A.NestedEnum}},
             5 =>
               {:repeated_nested_message, :unpacked, {:message, Namespace.Proto2A.NestedMessage}},
             6 => {:bytes, {:default, "`v"}, :bytes},
             126 => {:extension_int32, {:default, 0}, :int32},
             199 => {:extension_double, {:default, 42.42}, :double}
           }

    assert Namespace.Proto2B.syntax() == :proto2

    assert Namespace.Proto2B.defs() == %{
             1 =>
               {:optional_proto2a_nested_enum, {:default, :N_ZERO},
                {:enum, Namespace.Proto2A.NestedEnum}},
             2 =>
               {:required_proto2a_nested_enum, {:default, :N_THREE},
                {:enum, Namespace.Proto2A.NestedEnum}}
           }

    assert Namespace.Abc.Def.Proto3.syntax() == :proto3

    assert Namespace.Abc.Def.Proto3.defs() == %{
             1 => {:repeated_int32, :packed, :int32},
             2 => {:double, {:default, 0}, :double},
             3 => {:map_sfixed32_fixed64, :map, {:sfixed32, :fixed64}},
             4 => {:oneof_1_int32, {:oneof, :oneof_1}, :int32},
             5 => {:oneof_1_double, {:oneof, :oneof_1}, :double},
             6 =>
               {:oneof_1_foreign_enum, {:oneof, :oneof_1}, {:enum, Namespace.Abc.Def.ForeignEnum}},
             7 => {:oneof_1_proto2a, {:oneof, :oneof_1}, {:message, Namespace.Proto2A}},
             8 =>
               {:map_string_timestamp, :map,
                {:string, {:message, Namespace.Google.Protobuf.Timestamp}}},
             9 => {:bytes, {:default, ""}, :bytes},
             10 =>
               {:map_int64_nested_enum, :map,
                {:int64, {:enum, Namespace.Abc.Def.Proto3.NestedEnum}}},
             134 => {:oneof_2_int32, {:oneof, :oneof_2}, :int32},
             135 =>
               {:oneof_2_nested_enum, {:oneof, :oneof_2},
                {:enum, Namespace.Abc.Def.Proto3.NestedEnum}},
             9999 =>
               {:nested_enum, {:default, :FOO}, {:enum, Namespace.Abc.Def.Proto3.NestedEnum}}
           }
  end

  test "clear unknown fields" do
    assert %Proto2A{__uf__: [{10, 2, <<104, 101, 121, 33>>}]}
           |> Proto2A.clear_unknown_fields() == %Proto2A{}
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

  @tag conformance: true
  test "Launch conformance" do
    {:ok, _} = File.rm_rf("./failing_tests.txt")

    runner = System.get_env("PROTOBUF_CONFORMANCE_RUNNER")
    assert runner != nil, "PROTOBUF_CONFORMANCE_RUNNER not set"

    assert Mix.Tasks.Protox.Conformance.run(["--runner=#{runner}"]) == :ok,
           "Can't launch conformance test, please verify the conformance runner presence (#{
             runner
           })"

    # protobuf conformance runner produces this file only when some tests have failed
    refute File.exists?("./failing_tests.txt"),
           "Please check 'failing_tests.txt' file and 'conformance' directory for more information about this failure"
  end

  defp reencode_with_protoc(encoded, mod) do
    encoded_bin_path = Path.join([Mix.Project.build_path(), "protox_test_sub.bin"])

    File.write!(encoded_bin_path, encoded)

    encoded_txt_cmdline =
      "protoc --decode=#{mod} ./test/messages.proto ./test/protobuf2.proto  < #{encoded_bin_path}"

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    encoded_txt = "#{:os.cmd(String.to_charlist(encoded_txt_cmdline))}"

    encoded_txt_path = Path.join([Mix.Project.build_path(), "protox_test_sub.txt"])

    File.write!(encoded_txt_path, encoded_txt)

    reencoded_bin_path = Path.join([Mix.Project.build_path(), "protoc_test_sub.bin"])

    reencode_bin_cmdline =
      "protoc --encode=#{mod} ./test/messages.proto ./test/protobuf2.proto > #{reencoded_bin_path} < #{
        encoded_txt_path
      }"

    # credo:disable-for-next-line Credo.Check.Warning.UnsafeExec
    :os.cmd(String.to_charlist(reencode_bin_cmdline))

    File.read!(reencoded_bin_path)
  end
end
