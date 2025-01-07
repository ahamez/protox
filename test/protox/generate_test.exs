defmodule Protox.GenerateTest do
  use ExUnit.Case

  test "Generate code from a single proto file definition" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_file_name = "generated_code_1.ex"

    {:ok, files_content} =
      Protox.Generate.generate_module_code([file], generated_file_name, false, [
        "./test/samples"
      ])

    assert [%Protox.Generate.FileContent{name: ^generated_file_name, content: content}] =
             files_content

    tmp_dir = System.tmp_dir!()
    tmp_file = Path.join(tmp_dir, generated_file_name)
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

    assert [%Protox.Generate.FileContent{name: ^generated_file_name, content: content}] =
             files_content

    tmp_dir = System.tmp_dir!()
    tmp_file = Path.join(tmp_dir, generated_file_name)
    File.write!(tmp_file, content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    assert Code.compile_file(tmp_file) != []
  end

  test "Generate code from multiple proto files" do
    file = Path.join(__DIR__, "../samples/directory/sub_directory/sub_directory_message.proto")
    generated_path_name = "generated_code_1"

    {:ok, files_content} =
      Protox.Generate.generate_module_code([file], generated_path_name, _multiple_files = true, [
        "./test/samples"
      ])

    assert [
             %Protox.Generate.FileContent{
               name: "generated_code_1/directory_message1.ex",
               content: directory_message_1
             },
             %Protox.Generate.FileContent{
               name: "generated_code_1/sub_directory_message.ex",
               content: sub_directory_message
             }
           ] = files_content

    tmp_dir = System.tmp_dir!()
    sub_directory_message_tmp_file = Path.join(tmp_dir, "sub_directory_message.ex")
    directory_message_1_tmp_file = Path.join(tmp_dir, "directory_message_1.ex")
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
             %Protox.Generate.FileContent{
               name: "generated_code_2/namespace_directory_message1.ex",
               content: namespace_directory_message1_content
             },
             %Protox.Generate.FileContent{
               name: "generated_code_2/namespace_sub_directory_message.ex",
               content: namespace_sub_directory_message_content
             }
           ] = files_content

    tmp_dir = System.tmp_dir!()

    namespace_sub_directory_message_tmp_file =
      Path.join(tmp_dir, "namespace_sub_directory_message.ex")

    namespace_directory_message1_tmp_file = Path.join(tmp_dir, "namespace_directory_message1.ex")
    File.write!(namespace_sub_directory_message_tmp_file, namespace_sub_directory_message_content)
    File.write!(namespace_directory_message1_tmp_file, namespace_directory_message1_content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    # The order is important here to avoid compilation warnings
    assert Code.compile_file(namespace_directory_message1_tmp_file) != []
    assert Code.compile_file(namespace_sub_directory_message_tmp_file) != []
  end
end
