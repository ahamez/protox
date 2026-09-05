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

    refute content =~ ~r/repeated_bool.*\+\+/
    refute content =~ ~r/repeated_string.*\+\+/
    refute content =~ ~r/repeated_nested_message.*\+\+/

    prepend_and_reverse =
      ~r/
        repeated_string:\s*\[\s*
          Protox\.Decode\.validate_string!\(delimited\)\s*\|\s*
          :erlang\.map_get\(:repeated_string,\s*msg\)\s*
        \]
      /x

    assert content =~ prepend_and_reverse

    # Struct fields are read with :erlang.map_get/2, not `msg.field`, which would carry a dead
    # module-dispatch fallback arm. The public unknown_fields/1 accessor is the one exception:
    # it is not on a codec path, so it keeps the more idiomatic access.
    dot_accesses =
      ~r/\bmsg\.[a-z_]+/
      |> Regex.scan(content)
      |> List.flatten()
      |> Enum.uniq()

    assert dot_accesses == ["msg.__uf__"]

    assert content =~ "repeated_string: :lists.reverse(values)"
    assert content =~ "repeated_bool: :lists.reverse(values)"

    # Trivial defs are folded to the keyword form.
    assert content =~ "def encode(:FOO), do: 0\n"
    refute content =~ ~r/def encode\(:FOO\) do\n/

    # default/1 is a single schema lookup.
    assert content =~ "def default(field_name), do: Protox.MessageSchema.default(@schema, field_name)"
  end
end
