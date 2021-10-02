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
end
