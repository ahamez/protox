defmodule Protox.RandomInit.EdgeCase do
  @moduledoc false

  @behaviour Protox.RandomInit.Values

  import Bitwise

  # The default profile, used by the test suite. It deliberately over-produces awkward
  # values — NaN, Infinity, full-range integers, non-ASCII strings — because that is what
  # property tests should be probing.

  alias Protox.RandomInit.Values

  @impl Values
  def scalar({:enum, e}) do
    e.constants()
    |> Map.new()
    |> Map.values()
    |> StreamData.member_of()
  end

  def scalar(:bool), do: StreamData.boolean()

  def scalar(type) when type in [:int32, :int64, :sint32, :sint64, :sfixed32, :sfixed64] do
    StreamData.integer()
  end

  def scalar(type) when type in [:fixed32, :uint32], do: StreamData.integer(0..((1 <<< 32) - 1))
  def scalar(type) when type in [:fixed64, :uint64], do: StreamData.integer(0..((1 <<< 64) - 1))

  def scalar(:float) do
    StreamData.one_of([
      StreamData.map(StreamData.integer(-10_000..10_000), &(&1 * 1.0)),
      StreamData.constant(:nan),
      StreamData.constant(:infinity),
      StreamData.constant(:"-infinity")
    ])
  end

  def scalar(:double) do
    StreamData.one_of([
      StreamData.float(),
      StreamData.constant(:nan),
      StreamData.constant(:infinity),
      StreamData.constant(:"-infinity")
    ])
  end

  def scalar(:bytes), do: StreamData.binary()
  def scalar(:string), do: StreamData.string(:printable)

  @impl Values
  def collection(element, _depth), do: StreamData.list_of(element)

  @impl Values
  def presence(message, _depth), do: StreamData.one_of([StreamData.constant(nil), message])

  @impl Values
  def map(:bool, key, value), do: StreamData.map_of(key, value, max_length: 2, max_tries: 50)

  def map({:enum, e}, key, value) do
    StreamData.map_of(key, value, max_length: length(e.constants()), max_tries: 50)
  end

  def map(_key_type, key, value), do: StreamData.map_of(key, value, max_length: 20, max_tries: 50)
end
