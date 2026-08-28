defmodule Protox.Benchmark.RealisticValues do
  @moduledoc false

  @behaviour Protox.RandomInit.Values

  # Production-like value distributions for the benchmark corpus.
  #
  # The default profile (`Protox.RandomInit.EdgeCase`) is a property-testing generator: it
  # over-produces NaN, Infinity, full-range integers and non-ASCII strings on purpose.
  # Measured against the one captured corpus available (google_message1), that left 75% of
  # encoded floats on the NaN/Infinity branch, 45% of varints at their full 10-byte width
  # (every negative int32/int64 costs 10 bytes) and 94% of strings non-ASCII — none of
  # which resembles real traffic.
  #
  # The targets below are part measurement, part judgement: the captured reference is two
  # 228-byte messages with no floats and no populated repeated fields, so it pins down
  # density and varint width well and says nothing about the rest.
  #
  # Special values are kept at plausible rates rather than removed, so those encoder
  # branches stay exercised; the `edge_*` inputs saturate them for a sensitive signal.

  alias Protox.RandomInit.Values

  @ascii_alphabet ~c"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  # Real payloads repeat their keys and labels rather than carrying unique random text.
  @vocabulary ~w(
    id name type status code kind path host user agent region zone cluster node pod
    service method route target source label value count total sum error message
    request response trace span metric bucket sample series timestamp duration
  )

  @impl Values
  def scalar({:enum, e}) do
    e.constants()
    |> Map.new()
    |> Map.values()
    |> StreamData.member_of()
  end

  def scalar(:bool), do: StreamData.boolean()

  # Signed types. A negative int32/int64 always encodes as a full 10-byte varint, so its
  # rate matters a lot; the captured reference has none at all. sint* zigzags, making
  # negatives cheap, but it is rare enough in practice to share the same shape.
  def scalar(type) when type in [:int32, :sint32, :sfixed32] do
    signed_integer(2_147_483_647)
  end

  def scalar(type) when type in [:int64, :sint64, :sfixed64] do
    signed_integer(9_223_372_036_854_775_807)
  end

  def scalar(type) when type in [:uint32, :fixed32], do: unsigned_integer(4_294_967_295)
  def scalar(type) when type in [:uint64, :fixed64], do: unsigned_integer(18_446_744_073_709_551_615)

  def scalar(:float), do: real_number(StreamData.map(StreamData.integer(-10_000..10_000), &(&1 * 1.0)))
  def scalar(:double), do: real_number(StreamData.float())

  def scalar(:bytes) do
    StreamData.frequency([
      {70, sized_binary(8..64)},
      {25, sized_binary(65..512)},
      {5, sized_binary(513..4096)}
    ])
  end

  def scalar(:string) do
    StreamData.frequency([
      {95, ascii_string()},
      {5, StreamData.string(:printable, min_length: 1, max_length: 32)}
    ])
  end

  # Cardinality is skewed: most repeated fields hold nothing or a handful of elements, with
  # a long tail. The buckets scale with StreamData's size parameter, which is what
  # payloads.ex uses to place each input in its size band.
  #
  # At the recursion cutoff a nested message can only come out blank, and a swarm of
  # present-but-empty sub-messages is not what real payloads look like — it just makes the
  # encoder walk fields that are all at their default. Absent is the realistic answer.
  @impl Values
  def collection(_element, 0), do: StreamData.constant([])

  def collection(element, _depth) do
    StreamData.sized(fn size ->
      StreamData.frequency([
        {40, StreamData.constant([])},
        {40, list_up_to(element, max(1, div(size, 4)))},
        {15, list_up_to(element, max(2, size))},
        {5, list_up_to(element, max(4, size * 2))}
      ])
    end)
  end

  # Sub-messages are usually present in real data (100% in the captured reference); the
  # generator's depth limit is what stops recursion, so this only decides presence.
  @impl Values
  def presence(_message, 0), do: StreamData.constant(nil)

  def presence(message, _depth) do
    StreamData.frequency([{60, message}, {40, StreamData.constant(nil)}])
  end

  @impl Values
  def map(:bool, key, value), do: StreamData.map_of(key, value, max_length: 2, max_tries: 50)

  def map({:enum, e}, key, value) do
    StreamData.map_of(key, value, max_length: length(e.constants()), max_tries: 50)
  end

  def map(_key_type, key, value) do
    StreamData.sized(fn size ->
      StreamData.frequency([
        {30, StreamData.constant(%{})},
        {55, StreamData.map_of(key, value, max_length: max(1, div(size, 2)), max_tries: 50)},
        {15, StreamData.map_of(key, value, max_length: max(2, size * 2), max_tries: 50)}
      ])
    end)
  end

  # -- Private

  # ~15% zero (omitted on the wire by proto3), then mostly values that fit a one- or
  # two-byte varint, matching the 71% one-byte rate of the captured reference.
  defp unsigned_integer(max) do
    StreamData.frequency([
      {15, StreamData.constant(0)},
      {55, StreamData.integer(1..127)},
      {20, StreamData.integer(128..16_383)},
      {10, StreamData.integer(16_384..min(max, 268_435_455))}
    ])
  end

  defp signed_integer(max) do
    StreamData.frequency([{98, unsigned_integer(max)}, {2, StreamData.integer(-65_536..-1)}])
  end

  defp real_number(finite) do
    StreamData.frequency([
      {99, finite},
      {1, StreamData.member_of([:nan, :infinity, :"-infinity"])}
    ])
  end

  defp ascii_string() do
    StreamData.frequency([
      {70, StreamData.member_of(@vocabulary)},
      {25, sized_ascii(4..32)},
      {5, sized_ascii(33..320)}
    ])
  end

  defp list_up_to(element, max), do: StreamData.list_of(element, min_length: 1, max_length: max)

  defp sized_ascii(range) do
    StreamData.bind(StreamData.integer(range), fn length ->
      @ascii_alphabet
      |> StreamData.member_of()
      |> StreamData.list_of(length: length)
      |> StreamData.map(&List.to_string/1)
    end)
  end

  defp sized_binary(range) do
    StreamData.bind(StreamData.integer(range), fn length ->
      0..255
      |> StreamData.integer()
      |> StreamData.list_of(length: length)
      |> StreamData.map(&:erlang.list_to_binary/1)
    end)
  end
end
