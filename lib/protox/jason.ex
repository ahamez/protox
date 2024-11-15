defmodule Protox.Jason do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  if Code.ensure_loaded?(Jason) do
    @impl true
    def load(), do: :ok

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
  else
    @impl true
    def load(), do: :error

    @impl true
    def decode!(_iodata) do
      raise Protox.JsonDecodingError.new(
              "Jason library not loaded. Please check your project dependencies."
            )
    end

    @impl true
    def encode!(_term) do
      raise Protox.JsonEncodingError.new(
              "Jason library not loaded. Please check your project dependencies."
            )
    end
  end
end
