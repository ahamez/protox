defmodule Protox.GenerateTest do
  use ExUnit.Case, async: false

  alias Protox.Generate.FileContent

  test "generate_module_code/5 rejects invalid argument types" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")

    # These calls deliberately pass invalid argument types: they go through
    # apply/3 so the compiler's type checker does not flag them at compile time.
    for args <- [
          [file, "generated_code.ex", false, ["./test/samples"]],
          [[file], :generated_code, false, ["./test/samples"]],
          [[file], "generated_code.ex", nil, ["./test/samples"]]
        ] do
      assert %FunctionClauseError{module: Protox.Generate, function: :generate_module_code} =
               assert_raise(FunctionClauseError, fn ->
                 # credo:disable-for-next-line Credo.Check.Refactor.Apply
                 apply(Protox.Generate, :generate_module_code, args)
               end)
    end
  end

  test "Generate code from a single proto file definition" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_file_name = "generated_code_1.ex"

    {:ok, files_content} =
      Protox.Generate.generate_module_code([file], generated_file_name, false, [
        "./test/samples"
      ])

    assert [%FileContent{name: ^generated_file_name, content: content}] =
             files_content

    tmp_file = Protox.TmpFs.tmp_file_path!(generated_file_name)
    File.write!(tmp_file, content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    assert Code.compile_file(tmp_file) != []
  end

  test "Generate code from a single proto file with namespace" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_file_name = "generated_code_2.ex"

    {:ok, files_content} =
      Protox.Generate.generate_module_code(
        [file],
        generated_file_name,
        _multiple_files = false,
        ["./test/samples"],
        namespace: "Namespace"
      )

    assert [%FileContent{name: ^generated_file_name, content: content}] =
             files_content

    tmp_file = Protox.TmpFs.tmp_file_path!(generated_file_name)
    File.write!(tmp_file, content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    assert Code.compile_file(tmp_file) != []
  end

  test "Generate code in multiple files" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_path_name = "generated_code_1"

    {:ok, files_content} =
      Protox.Generate.generate_module_code(
        [file],
        generated_path_name,
        _multiple_files = true,
        ["./test/samples"]
      )

    assert [
             %FileContent{
               name: "generated_code_1/directory_message1.ex",
               content: directory_message_1
             },
             %FileContent{
               name: "generated_code_1/sub_directory_message.ex",
               content: sub_directory_message
             }
           ] = files_content

    sub_directory_message_tmp_file = Protox.TmpFs.tmp_file_path!("sub_directory_message.ex")
    directory_message_1_tmp_file = Protox.TmpFs.tmp_file_path!("directory_message_1.ex")
    File.write!(sub_directory_message_tmp_file, sub_directory_message)
    File.write!(directory_message_1_tmp_file, directory_message_1)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    # The order is important here to avoid compilation warnings
    assert Code.compile_file(directory_message_1_tmp_file) != []
    assert Code.compile_file(sub_directory_message_tmp_file) != []
  end

  test "Generate code in multiple files with namespace" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_path_name = "generated_code_2"

    {:ok, files_content} =
      Protox.Generate.generate_module_code(
        [file],
        generated_path_name,
        _multiple_files = true,
        ["./test/samples"],
        namespace: "Namespace"
      )

    assert [
             %FileContent{
               name: "generated_code_2/namespace_directory_message1.ex",
               content: namespace_directory_message1_content
             },
             %FileContent{
               name: "generated_code_2/namespace_sub_directory_message.ex",
               content: namespace_sub_directory_message_content
             }
           ] = files_content

    namespace_sub_directory_message_tmp_file =
      Protox.TmpFs.tmp_file_path!("namespace_sub_directory_message.ex")

    namespace_directory_message1_tmp_file =
      Protox.TmpFs.tmp_file_path!("namespace_directory_message1.ex")

    File.write!(namespace_sub_directory_message_tmp_file, namespace_sub_directory_message_content)
    File.write!(namespace_directory_message1_tmp_file, namespace_directory_message1_content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    # The order is important here to avoid compilation warnings
    assert Code.compile_file(namespace_directory_message1_tmp_file) != []
    assert Code.compile_file(namespace_sub_directory_message_tmp_file) != []
  end

  test "Generate repeated-field decoders with prepend-and-reverse" do
    file = Path.join(__DIR__, "../samples/google/test_messages_proto3.proto")
    generated_file_name = "generated_repeated_decode.ex"

    {:ok, files_content} =
      Protox.Generate.generate_module_code([file], generated_file_name, false, [
        "./test/samples/google"
      ])

    assert [%FileContent{name: ^generated_file_name, content: content}] =
             files_content

    content = IO.iodata_to_binary(content)

    refute content =~ "msg.repeated_bool ++"
    refute content =~ "msg.repeated_string ++"
    refute content =~ "msg.repeated_nested_message ++"

    assert content =~
             ~r/repeated_string:\s*\[\s*Protox\.Decode\.validate_string!\(delimited\)\s*\|\s*msg\.repeated_string\s*\]/s

    assert content =~ "repeated_string: Enum.reverse(msg.repeated_string)"
    assert content =~ "repeated_bool: Enum.reverse(msg.repeated_bool)"
  end
end
