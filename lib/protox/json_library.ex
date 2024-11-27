defmodule Protox.JsonLibrary do
  @moduledoc """
  The behaviour to implement when wrapping a JSON library.
  """

  @default_json_library Jason

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonDecodingError.
  """
  @callback decode!(iodata()) :: term() | no_return()

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonEncodingError.
  """
  @callback encode!(term()) :: iodata() | no_return()

  @doc false
  def get_wrapper(opts) do
    json_library = Keyword.get(opts, :json_library, @default_json_library)

    if Code.ensure_loaded?(json_library) do
      Module.concat(Protox, json_library)
    else
      nil
    end
  end
end
