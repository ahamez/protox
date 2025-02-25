defmodule Protox.String do
  @moduledoc false

  if Mix.env() == :test do
    @max_size Bitwise.<<<(1, 20)
    def max_size(), do: @max_size
  else
    # Reference: https://protobuf.dev/programming-guides/proto3/#scalar
    @max_size Bitwise.<<<(1, 32)
  end

  def validate(bytes) do
    cond do
      not String.valid?(bytes) ->
        {:error, :invalid_utf8}

      byte_size(bytes) > @max_size ->
        {:error, :too_large}

      true ->
        :ok
    end
  end
end
