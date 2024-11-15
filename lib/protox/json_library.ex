defmodule Protox.JsonLibrary do
  @moduledoc """
  The behaviour to implement when wrapping a JSON library.
  """

  @callback load() :: :ok | :error

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonDecodingError.
  """
  @callback decode!(iodata()) :: term() | no_return()

  @doc """
  Should wrap any exception of the underlying library in Protox.JsonEncodingError.
  """
  @callback encode!(term()) :: iodata() | no_return()

  @doc false
  def get_library(opts, decoding_or_encoding) do
    json_library_name = Keyword.get(opts, :json_library, Jason)
    json_library_wrapper = Module.concat(Protox, json_library_name)

    case json_library_wrapper.load() do
      :ok ->
        json_library_wrapper

      :error ->
        message = "cannot load JSON library. Please check your project dependencies."

        case decoding_or_encoding do
          :decode -> raise Protox.JsonDecodingError.new(message)
          :encode -> raise Protox.JsonEncodingError.new(message)
        end
    end
  end
end
