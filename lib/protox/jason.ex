defmodule Protox.Jason do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  @impl true
  def load() do
    if Code.ensure_loaded?(Jason) do
      {:ok, Jason}
    else
      :error
    end
  end

  @impl true
  def decode!(jason_module, iodata) do
    try do
      jason_module.decode!(iodata)
    rescue
      e in Jason.DecodeError ->
        reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end

  @impl true
  def encode!(jason_module, term) do
    try do
      jason_module.encode!(term)
    rescue
      e in Jason.EncodeError ->
        reraise Protox.JsonEncodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end
end
