defmodule Protox.TmpFs do
  @moduledoc false

  @basename "protox-#{Mix.Project.config()[:version]}"

  def tmp_dir!(suffix \\ "") do
    path = Path.join([System.tmp_dir!(), @basename, suffix])
    File.mkdir_p!(path)

    path
  end

  def tmp_file_path!(suffix \\ "") do
    Path.join(tmp_dir!(), random_string() <> suffix)
  end

  defp random_string(len \\ 16) do
    "#{Enum.take_random(?a..?z, len)}"
  end
end
