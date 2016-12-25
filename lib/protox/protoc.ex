defmodule Protox.Protoc do

  @moduledoc false

  def run(proto_files) do
    # file = "#{Mix.Project.build_path}/protox_#{random_filename()}"
    file = "foo.bin"
    ret = System.cmd(
      "protoc",
      ["--include_imports", "-o", file] ++ proto_files
    )

    case ret do
      {_, 0}   -> {:ok, File.read!(file)}
      {msg, _} -> {:error, msg}
    end
  end


  # -- Private


  defp random_filename() do
    "#{Enum.take_random(?a..?z, 16)}"
  end

end
