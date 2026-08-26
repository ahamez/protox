defmodule Protox.String do
  @moduledoc false

  if Mix.env() == :test do
    @max_size Bitwise.<<<(1, 20)
    @spec max_size() :: pos_integer()
    def max_size(), do: @max_size
  else
    # Reference: https://protobuf.dev/programming-guides/proto3/#scalar
    @max_size Bitwise.<<<(1, 32)
  end

  @spec validate(binary()) :: :ok | {:error, :invalid_utf8 | :too_large}
  def validate(bytes) do
    cond do
      byte_size(bytes) > @max_size ->
        {:error, :too_large}

      not String.valid?(bytes) ->
        {:error, :invalid_utf8}

      true ->
        :ok
    end
  end
end
