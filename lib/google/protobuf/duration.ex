defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Duration do
  def decode_message(initial_message, json) do
    dec = get_decimal(json)

    {seconds, nanos} = get_seconds_nanos(dec)

    cond do
      seconds < -315_576_000_000 ->
        raise Protox.JsonDecodingError.new("#{seconds} is < -315_576_000_000")

      seconds > 315_576_000_000 ->
        raise Protox.JsonDecodingError.new("#{seconds} is > 315_576_000_000")

      nanos < -999_999_999 ->
        raise Protox.JsonDecodingError.new("#{nanos} is < -999_999_999")

      nanos > 999_999_999 ->
        raise Protox.JsonDecodingError.new("#{nanos} is > 999_999_999")

      true ->
        struct!(initial_message, seconds: seconds, nanos: nanos)
    end
  end

  # -- Private

  defp get_decimal(json) do
    case Decimal.parse(json) do
      {dec, "s"} -> dec
      {_dec, _suffix} -> raise Protox.JsonDecodingError.new("invalid duration format")
      :error -> raise Protox.JsonDecodingError.new("invalid duration format")
    end
  end

  defp get_seconds_nanos(dec) do
    seconds =
      if Decimal.negative?(dec) do
        Decimal.round(dec, 0, :ceiling)
      else
        Decimal.round(dec, 0, :floor)
      end

    nanos = Decimal.mult(Decimal.sub(dec, seconds), 1_000_000_000)

    {Decimal.to_integer(seconds), Decimal.to_integer(nanos)}
  end
end

defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Duration do
  def encode_message(msg, json_encode) do
    cond do
      msg.seconds < -315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "#{msg.seconds} is < -315_576_000_000")

      msg.seconds > 315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "#{msg.seconds} is > 315_576_000_000")

      msg.nanos < -999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "#{msg.nanos} is < -999_999_999")

      msg.nanos > 999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "#{msg.nanos} is > 999_999_999")

      true ->
        duration =
          Decimal.add(
            Decimal.new(msg.seconds),
            Decimal.div(Decimal.new(msg.nanos), Decimal.new(1_000_000_000))
          )

        digits =
          cond do
            rem(msg.nanos, 1_000_000_000) == 0 -> 0
            rem(msg.nanos, 1_000_000) == 0 -> 3
            rem(msg.nanos, 1000) == 0 -> 6
            true -> 9
          end

        json_encode.("#{Decimal.round(duration, digits)}s")
    end
  end
end
