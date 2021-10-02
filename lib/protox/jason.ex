defmodule Protox.Jason do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  @impl true
  def decode!(iodata) do
    try do
      Jason.decode!(iodata)
    rescue
      e in Jason.DecodeError ->
        reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end

  @impl true
  def encode!(term) do
    try do
      Jason.encode!(term)
    rescue
      e in Jason.EncodeError ->
        reraise Protox.JsonEncodingError.new(Exception.message(e)), __STACKTRACE__
    end
  end
end
