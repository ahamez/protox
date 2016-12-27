defmodule Protox.Util do

  @moduledoc false

  def random_string(len \\ 16) do
    "#{Enum.take_random(?a..?z, len)}"
  end

end
