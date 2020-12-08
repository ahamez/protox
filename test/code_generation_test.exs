defmodule Protox.CodeGenerationTest do
  use ExUnit.Case

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
