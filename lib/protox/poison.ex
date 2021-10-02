defmodule Protox.Poison do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  @impl true
  def load() do
    if Code.ensure_loaded?(Poison) do
      {:ok, Poison}
    else
      :error
    end
  end

  @impl true
  def decode!(poison_module, iodata) do
    try do
      poison_module.decode!(iodata)
    rescue
      e in Poison.DecodeError ->
        reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end

  @impl true
  def encode!(poison_module, term) do
    try do
      poison_module.encode!(term)
    rescue
      e in Poison.EncodeError ->
        reraise Protox.JsonEncodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end
end
