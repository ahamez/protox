defmodule Protox.Poison do
  @moduledoc false

  if Code.ensure_loaded?(Poison) do
    @behaviour Protox.JsonLibrary

    @impl true
    def decode!(iodata) do
      try do
        Poison.decode!(iodata)
      rescue
        e in [Poison.DecodeError, Poison.ParseError] ->
          reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
      end
    end

    @impl true
    def encode!(term) do
      try do
        Poison.encode!(term)
      rescue
        e in Poison.EncodeError ->
          reraise Protox.JsonEncodingError.new(Exception.message(e)), __STACKTRACE__
      end
    end
  end
end
