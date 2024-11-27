defmodule Protox.Jason do
  @moduledoc false

  if Code.ensure_loaded?(Jason) do
    @behaviour Protox.JsonLibrary

    @impl true
    def decode!(iodata) do
      try do
        Jason.decode!(iodata)
      rescue
        e in [Jason.DecodeError, Protocol.UndefinedError] ->
          reraise Protox.JsonDecodingError.new(Exception.message(e)), __STACKTRACE__
      end
    end

    @impl true
    def encode!(term) do
      try do
        Jason.encode_to_iodata!(term)
      rescue
        e in Jason.EncodeError ->
          reraise Protox.JsonEncodingError.new(Exception.message(e)), __STACKTRACE__
      end
    end
  end
end
