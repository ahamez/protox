defmodule Protox.Protoc do

  @moduledoc false

  def run(proto_files) do
    filename = Protox.Util.random_string()
    file = "#{Mix.Project.build_path}/protox_#{filename}"
    ret = System.cmd(
      "protoc",
      ["--include_imports", "-o", file] ++ proto_files
    )

    case ret do
      {_, 0}   -> {:ok, File.read!(file)}
      {msg, _} -> {:error, msg}
    end
  end

end
