defmodule Protox.JsonLibrary do
  @moduledoc """
  The behaviour to implement when wrapping a JSON library.
  """

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonDecodingError.
  """
  @callback decode!(iodata()) :: term() | no_return()

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonEncodingError.
  """
  @callback encode!(term()) :: iodata() | no_return()

  @doc false
  def get_wrapper(json_library) do
    if Code.ensure_loaded?(json_library) do
      Module.concat(Protox, json_library)
    else
      raise Protox.JsonLibraryError.new()
    end
  end
end
