defmodule Protox.Protoc do
  @moduledoc false

  def run([proto_file], nil) do
    do_run([proto_file], ["-I", "#{proto_file |> Path.dirname() |> Path.expand()}"])
  end

  def run([proto_file], paths) do
    do_run([proto_file], paths_to_protoc_args(paths))
  end

  def run(proto_files, nil) do
    do_run(proto_files, ["-I", "#{common_directory_path(proto_files)}"])
  end

  def run(proto_files, paths) do
    do_run(proto_files, paths_to_protoc_args(paths))
  end

  # -- Private

  defp paths_to_protoc_args(paths) do
    paths |> Enum.map(&["-I", &1]) |> Enum.concat()
  end

  defp do_run(proto_files, args) do
    outfile_name = "protox_#{random_string()}"
    outfile_path = Path.join([Mix.Project.build_path(), outfile_name])

    cmd_args = ["--include_imports", "-o", outfile_path] ++ args ++ proto_files

    try do
      System.cmd("protoc", cmd_args, stderr_to_stdout: true)
    catch
      :error, :enoent ->
        raise "protoc executable is missing. Please make sure Protocol Buffers " <>
                "is installed and available system wide"
    else
      {_, 0} ->
        file_content = File.read!(outfile_path)
        :ok = File.rm(outfile_path)
        {:ok, file_content}

      {msg, _} ->
        {:error, msg}
    end
  end

  defp common_directory_path(paths_rel) do
    paths = Enum.map(paths_rel, &Path.expand/1)

    min_path = paths |> Enum.min() |> Path.split()
    max_path = paths |> Enum.max() |> Path.split()

    min_path
    |> Enum.zip(max_path)
    |> Enum.take_while(fn {a, b} -> a == b end)
    |> Enum.map(fn {x, _} -> x end)
    |> Path.join()
  end

  @spec random_string(non_neg_integer) :: String.t()
  defp random_string(len \\ 16) do
    "#{Enum.take_random(?a..?z, len)}"
  end
end
