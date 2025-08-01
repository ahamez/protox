defmodule Protox.Varint.Native do
  @moduledoc false
  use Rustler, otp_app: :protox, crate: "varint_nif"

  def encode(_int), do: :erlang.nif_error(:nif_not_loaded)
  def decode(_bin), do: :erlang.nif_error(:nif_not_loaded)
end
