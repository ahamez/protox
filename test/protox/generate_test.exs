defmodule Protox.GenerateTest do
  use ExUnit.Case

  test "Generate code in a single file" do
    file = Path.join(__DIR__, "../samples/prefix/bar/bar.proto")
    generated_file_name = "generated_code.ex"

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

  test "Generate code in a single file with namespace" do
    file = Path.join(__DIR__, "../samples/prefix/bar/bar.proto")
    generated_file_name = "generated_code.ex"

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

  test "Generate code in multiple files" do
    file = Path.join(__DIR__, "../samples/prefix/bar/bar.proto")
    generated_path_name = "generated_code"

    {:ok, files_content} =
      Protox.Generate.generate_module_code([file], generated_path_name, true, [
        "./test/samples"
      ])

    assert [
             %Protox.Generate.FileContent{
               name: "generated_code/bar.ex",
               content: bar_content
             },
             %Protox.Generate.FileContent{
               name: "generated_code/foo.ex",
               content: foo_content
             }
           ] = files_content

    tmp_dir = System.tmp_dir!()
    bar_tmp_file = Path.join(tmp_dir, "bar.ex")
    foo_tmp_file = Path.join(tmp_dir, "foo.ex")
    File.write!(bar_tmp_file, bar_content)
    File.write!(foo_tmp_file, foo_content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    # The order is important here to avoid compilation warnings
    assert Code.compile_file(foo_tmp_file) != []
    assert Code.compile_file(bar_tmp_file) != []
  end

  test "Generate code in multiple files with namespace" do
    file = Path.join(__DIR__, "../samples/prefix/bar/bar.proto")
    generated_path_name = "generated_code"

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
               name: "generated_code/namespace_bar.ex",
               content: bar_content
             },
             %Protox.Generate.FileContent{
               name: "generated_code/namespace_foo.ex",
               content: foo_content
             }
           ] = files_content

    tmp_dir = System.tmp_dir!()
    bar_tmp_file = Path.join(tmp_dir, "bar.ex")
    foo_tmp_file = Path.join(tmp_dir, "foo.ex")
    File.write!(bar_tmp_file, bar_content)
    File.write!(foo_tmp_file, foo_content)

    # To avoid warning conflicts with other tests compiling code
    Code.compiler_options(ignore_module_conflict: true)

    # The order is important here to avoid compilation warnings
    assert Code.compile_file(foo_tmp_file) != []
    assert Code.compile_file(bar_tmp_file) != []
  end
end
