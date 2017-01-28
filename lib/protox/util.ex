defmodule Protox.Util do

  @moduledoc false


  @spec random_string(non_neg_integer) :: String.t
  def random_string(len \\ 16) do
    "#{Enum.take_random(?a..?z, len)}"
  end

end
