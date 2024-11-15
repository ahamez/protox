defmodule Protox.Poison do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  if Code.ensure_loaded?(Poison) do
    @impl true
    def load(), do: :ok

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
  else
    @impl true
    def load(), do: :error

    @impl true
    def decode!(_iodata) do
      raise Protox.JsonDecodingError.new(
              "Poison library not loaded. Please check your project dependencies."
            )
    end

    @impl true
    def encode!(_term) do
      raise Protox.JsonEncodingError.new(
              "Poison library not loaded. Please check your project dependencies."
            )
    end
  end
end
