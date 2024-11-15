defmodule Protox.Poison do
  @moduledoc false
  @behaviour Protox.JsonLibrary

  if Code.ensure_loaded?(Poison) do
    @impl true
    def load() do
      {:ok, Poison}
    end

    @impl true
    def decode!(poison_module, iodata) do
      try do
        poison_module.decode!(iodata)
      rescue
        e in [Poison.DecodeError, Poison.ParseError] ->
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
  else
    @impl true
    def load() do
      :error
    end

    @impl true
    def decode!(_poison_module, _iodata) do
      raise Protox.JsonDecodingError.new(
              "Poison library not loaded. Please check your project dependencies."
            )
    end

    @impl true
    def encode!(_poison_module, _term) do
      raise Protox.JsonEncodingError.new(
              "Poison library not loaded. Please check your project dependencies."
            )
    end
  end
end
