defmodule Mix.Tasks.Protox.Conformance do
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  @spec run(any) :: any
  def run(args) do
    with {options, _, []} <-
           OptionParser.parse(args,
             strict: [
               runner: :string,
               quiet: :boolean,
               force_runner_build: :boolean,
               compile_only: :boolean
             ]
           ),
         {:ok, runner} <- get_runner(options),
         :ok <- Mix.Tasks.Escript.Build.run([]),
         :ok <- launch_runner(options, runner) do
      {:ok, :conformance_successful}
    else
      # We return :ok here because it means that the conformance test was launched, not necessarily successful.
      {:error, :runner_failure} -> {:ok, :conformance_failure}
      e -> e
    end
  end

  defp launch_runner(options, runner) do
    compile_only = Keyword.get(options, :compile_only, false)

    if compile_only do
      :ok
    else
      shell = shell(options)

      cmd =
        shell.cmd(
          "#{runner} --enforce_recommended --failure_list ./conformance/failure_list.txt --output_dir . ./protox_conformance"
        )

      case cmd do
        0 -> :ok
        1 -> {:error, :runner_failure}
        126 -> {:error, :cannot_execute_runner}
        127 -> {:error, :no_such_file_or_directory}
        code -> {:error, code}
      end
    end
  end

  defp get_runner(options) do
    case Keyword.get(options, :runner) do
      nil ->
        runner_path =
          Path.expand("#{Mix.Project.deps_paths().protobuf}/bin/conformance_test_runner")

        force_runner_build = Keyword.get(options, :force_runner_build, false)

        if File.exists?(runner_path) and not force_runner_build do
          {:ok, runner_path}
        else
          with :ok <- configure_runner(options),
               :ok <- build_runner(options) do
            {:ok, runner_path}
          end
        end

      runner_path ->
        {:ok, runner_path}
    end
  end

  defp configure_runner(options) do
    shell = shell(options)

    configuration =
      [
        {"CMAKE_CXX_STANDARD", "14"},
        {"protobuf_INSTALL", "OFF"},
        {"protobuf_BUILD_TESTS", "OFF"},
        {"protobuf_BUILD_CONFORMANCE", "ON"},
        {"protobuf_BUILD_EXAMPLES", "OFF"},
        {"protobuf_BUILD_PROTOBUF_BINARIES", "ON"},
        {"protobuf_BUILD_PROTOC_BINARIES", "OFF"},
        {"protobuf_BUILD_LIBPROTOC", "OFF"},
        {"protobuf_BUILD_LIBUPB", "OFF"}
      ]
      |> Enum.map(fn {key, value} -> "-D#{key}=#{value}" end)
      |> Enum.join(" ")

    File.cd!(Mix.Project.deps_paths().protobuf, fn ->
      cmd = shell.cmd("cmake . #{configuration}")

      case cmd do
        0 -> :ok
        code -> {:error, code}
      end
    end)
  end

  defp build_runner(options) do
    shell = shell(options)

    File.cd!(Mix.Project.deps_paths().protobuf, fn ->
      cmd = shell.cmd("cmake --build . --parallel")

      case cmd do
        0 -> :ok
        code -> {:error, code}
      end
    end)
  end

  defp shell(options) do
    case Keyword.get(options, :quiet, false) do
      true -> Mix.Shell.Quiet
      false -> Mix.Shell.IO
    end
  end
end
