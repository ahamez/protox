defmodule Protox.CodeGenerationTest do
  use ExUnit.Case

  setup_all _context do
    {_, 0} = System.cmd("mix", ["do", "deps.get,", "deps.compile"], cd: "code_generation")

    :ok
  end

  defp launch(output, args) do
    File.rm_rf!("./code_generation/lib/output")
    File.mkdir_p!("./code_generation/lib/output")

    {_, generation_exit_status} =
      System.cmd(
        "mix",
        [
          "protox.generate",
          "--output-path=./lib/output/#{output}",
          "../test/samples/proto3.proto"
        ] ++ args,
        cd: "code_generation"
      )

    assert generation_exit_status == 0

    {_, compilation_exit_status} =
      System.cmd(
        "mix",
        [
          "compile"
        ],
        cd: "code_generation"
      )

    assert compilation_exit_status == 0

    {_, credo_exit_status} =
      System.cmd(
        "mix",
        [
          "credo"
        ],
        cd: "code_generation"
      )

    assert credo_exit_status == 0
  end

  test "Generate single file, with unknown fields" do
    launch("single_with_unknown_fields.ex", [])
  end

  test "Generate single file, without unknown fields" do
    launch("single_without_unknown_fields.ex", ["--keep-unknown-fields=false"])
  end

  test "Generate multiple files, with unknown fields" do
    launch(".", ["--multiple-files"])
  end

  test "Generate multiple files, without unknown fields" do
    launch(".", ["--multiple-files", "--keep-unknown-fields=false"])
  end

  test "Generate single file, with namespace" do
    launch("single_with_namespace.ex", ["--namespace=Namespace"])
  end

  test "Generate multiple files, with namespace" do
    launch(".", ["--multiple-files", "--namespace=Namespace"])
  end

  test "Mix task generates a file that can be compiled" do
    tmp_dir = System.tmp_dir!()
    tmp_file = Path.join(tmp_dir, "file.ex")

    Mix.Tasks.Protox.Generate.run([
      "--output-path=#{tmp_file}",
      "./test/samples/proto3.proto"
    ])

    assert length(Code.compile_file(tmp_file)) > 0

    File.rm!(tmp_file)
  end
end
