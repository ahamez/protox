defmodule Protox.StringTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @valid [
    {"empty", <<>>},
    {"ascii", "hello"},
    {"NUL byte", <<0>>},
    {"two-byte sequence", <<0xC3, 0xA9>>},
    {"three-byte sequence", <<0xE6, 0x97, 0xA5>>},
    {"BOM", <<0xEF, 0xBB, 0xBF>>},
    {"lowest four-byte sequence (U+10000)", <<0xF0, 0x90, 0x80, 0x80>>},
    {"highest code point (U+10FFFF)", <<0xF4, 0x8F, 0xBF, 0xBF>>}
  ]

  @invalid [
    {"above U+10FFFF", <<0xF4, 0x90, 0x80, 0x80>>},
    {"five-byte sequence", <<0xF8, 0x88, 0x80, 0x80, 0x80>>},
    {"low surrogate half (U+D800)", <<0xED, 0xA0, 0x80>>},
    {"high surrogate half (U+DFFF)", <<0xED, 0xBF, 0xBF>>},
    {"CESU-8 surrogate pair", <<0xED, 0xA0, 0xBD, 0xED, 0xB8, 0x80>>},
    {"overlong NUL", <<0xC0, 0x80>>},
    {"overlong solidus", <<0xE0, 0x80, 0xAF>>},
    {"overlong four-byte", <<0xF0, 0x80, 0x80, 0xAF>>},
    {"lone continuation byte", <<0x80>>},
    {"truncated two-byte sequence", <<0xC3>>},
    {"truncated three-byte sequence", <<0xE6, 0x97>>},
    {"truncated four-byte sequence", <<0xF0, 0x90, 0x80>>},
    {"0xFE", <<0xFE>>},
    {"0xFF", <<0xFF>>},
    {"valid prefix, invalid tail", <<"ok", 0xC3>>},
    {"invalid prefix, valid tail", <<0xC3, "ok">>}
  ]

  for {description, bytes} <- @valid do
    test "accepts #{description}" do
      assert Protox.String.validate(unquote(bytes)) == :ok
    end
  end

  for {description, bytes} <- @invalid do
    test "rejects #{description}" do
      assert Protox.String.validate(unquote(bytes)) == {:error, :invalid_utf8}
    end
  end

  test "rejects a string larger than the maximum size" do
    oversized = <<0::integer-size(Protox.String.max_size() + 1)-unit(8)>>

    assert Protox.String.validate(oversized) == {:error, :too_large}
  end

  test "reports the size before looking at the contents" do
    # An oversized *and* invalid string is reported as too large: the size check comes first
    # so a huge binary is never walked.
    oversized = <<0xFF, 0::integer-size(Protox.String.max_size())-unit(8)>>

    assert Protox.String.validate(oversized) == {:error, :too_large}
  end

  # validate/1 picks its UTF-8 check by size, so both branches need covering. 4096 bytes is
  # the boundary; these sit either side of it without depending on the exact value.
  @below_threshold 1024
  @above_threshold 16_384

  for size <- [@below_threshold, @above_threshold] do
    test "accepts a valid #{size}-byte string" do
      assert Protox.String.validate(:binary.copy("aé", div(unquote(size), 3))) == :ok
    end

    test "rejects a #{size}-byte string whose last byte is invalid" do
      bytes = :binary.copy("a", unquote(size)) <> <<0xFF>>

      assert Protox.String.validate(bytes) == {:error, :invalid_utf8}
    end

    test "rejects a #{size}-byte string whose first byte is invalid" do
      bytes = <<0xFF>> <> :binary.copy("a", unquote(size))

      assert Protox.String.validate(bytes) == {:error, :invalid_utf8}
    end
  end

  test "raises on a value that is not a binary, as byte_size/1 does" do
    assert_raise ArgumentError, fn -> Protox.String.validate(~c"charlist") end
  end

  test "agrees with String.valid?/1 on every one-byte and two-byte binary" do
    for a <- 0..255 do
      assert_agrees(<<a>>)

      for b <- 0..255 do
        assert_agrees(<<a, b>>)
      end
    end
  end

  property "agrees with String.valid?/1 on arbitrary binaries" do
    check all(bytes <- StreamData.binary(max_length: 16)) do
      assert_agrees(bytes)
    end
  end

  property "agrees with String.valid?/1 on sequences built from UTF-8 lead and continuation bytes" do
    # Random binaries almost never form a multi-byte sequence; these do, which is where the
    # surrogate and overlong disagreements would hide.
    lead =
      StreamData.one_of([
        StreamData.integer(0xC0..0xDF),
        StreamData.integer(0xE0..0xEF),
        StreamData.integer(0xF0..0xF7)
      ])

    continuation = StreamData.integer(0x80..0xBF)

    check all(
            lead <- lead,
            continuations <- StreamData.list_of(continuation, min_length: 1, max_length: 3)
          ) do
      assert_agrees(:erlang.list_to_binary([lead | continuations]))
    end
  end

  defp assert_agrees(bytes) do
    expected = if String.valid?(bytes), do: :ok, else: {:error, :invalid_utf8}

    assert Protox.String.validate(bytes) == expected, """
    disagreed with String.valid?/1 on #{inspect(bytes)}
    """
  end
end
