defmodule Protox.CodeGenerationTest do
  use ExUnit.Case, async: false

  @moduletag :slow
  @moduletag timeout: 600_000

  setup_all _context do
    tmp_dir = Protox.TmpFs.tmp_dir!()
    code_generation_path = "#{tmp_dir}/code_generation"

    # Remove possible leftovers
    File.rm_rf!(code_generation_path)

    {_, 0} = System.cmd("mix", ["new", "code_generation"], cd: tmp_dir)
    File.write!("#{code_generation_path}/mix.exs", mix_exs())

    {_, 0} = System.cmd("mix", ["do", "deps.get,", "deps.compile"], cd: code_generation_path)

    on_exit(fn -> File.rm_rf!(code_generation_path) end)

    {:ok, %{code_generation_path: code_generation_path, protox_path: File.cwd!()}}
  end

  test "Generate single file, with unknown fields", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, "single_with_unknown_fields.ex", [])
  end

  test "Generate single file, without unknown fields", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, "single_without_unknown_fields.ex", ["--generate=none"])
  end

  test "Generate multiple files, with unknown fields", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, ".", ["--multiple-files"])
  end

  test "Generate multiple files, without unknown fields", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, ".", ["--multiple-files", "--generate=none"])
  end

  test "Generate single file, with namespace", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, "single_with_namespace.ex", ["--namespace=Namespace"])
  end

  test "Generate multiple files, with namespace", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    launch(path, protox_path, ".", ["--multiple-files", "--namespace=Namespace"])
  end

  test "Mix task generates a file that can be compiled", %{
    protox_path: protox_path
  } do
    tmp_file = Protox.TmpFs.tmp_file_path!(".ex")

    Mix.Tasks.Protox.Generate.run([
      "--output-path=#{tmp_file}",
      "#{protox_path}/test/samples/proto3.proto"
    ])

    assert length(Code.compile_file(tmp_file)) > 0

    File.rm!(tmp_file)
  end

  test "Don't generate when definition is invalid", %{
    code_generation_path: path,
    protox_path: protox_path
  } do
    File.rm_rf!("#{path}/lib/output")
    File.mkdir_p!("#{path}/lib/output")

    {_, generation_exit_status} =
      System.cmd(
        "mix",
        [
          "protox.generate",
          "--output-path=./lib/output/should_fail.ex",
          "#{protox_path}/test/samples/invalid.proto"
        ],
        cd: path,
        stderr_to_stdout: true
      )

    assert generation_exit_status == 1
  end

  defp launch(code_generation_path, protox_path, output, args) do
    File.rm_rf!("#{code_generation_path}/lib/output")
    File.mkdir_p!("#{code_generation_path}/lib/output")

    {_, generation_exit_status} =
      System.cmd(
        "mix",
        [
          "protox.generate",
          "--output-path=./lib/output/#{output}",
          "#{protox_path}/test/samples/proto3.proto"
        ] ++ args,
        cd: code_generation_path
      )

    assert generation_exit_status == 0

    {_, compilation_exit_status} =
      System.cmd(
        "mix",
        [
          "compile",
          "--warnings-as-errors"
        ],
        cd: code_generation_path
      )

    assert compilation_exit_status == 0

    {_, credo_exit_status} =
      System.cmd(
        "mix",
        [
          "credo"
        ],
        cd: code_generation_path
      )

    assert credo_exit_status == 0

    {_, mix_format_exit_status} =
      System.cmd(
        "mix",
        [
          "format",
          "--check-formatted"
        ],
        cd: code_generation_path
      )

    assert mix_format_exit_status == 0

    {_, mix_dialyzer_exit_status} =
      System.cmd(
        "mix",
        [
          "dialyzer"
        ],
        cd: code_generation_path
      )

    assert mix_dialyzer_exit_status == 0
  end

  defp mix_exs() do
    """
    defmodule CodeGeneration.MixProject do
      use Mix.Project

      def project do
        [
          app: :code_generation,
          version: "0.1.0",
          elixir: "~> #{System.version()}",
          start_permanent: Mix.env() == :prod,
          deps: deps()
        ]
      end

      def application do
        [
          extra_applications: [:logger]
        ]
      end

      defp deps do
        [
          {:protox, path: "#{File.cwd!()}"},
          {:dialyxir, "~> 1.0", only: [:test, :dev], runtime: false},
          {:credo, "~> 1.4", only: [:test, :dev], runtime: false}
        ]
      end
    end
    """
  end
end
