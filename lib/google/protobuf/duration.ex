defimpl Protox.JsonMessageEncoder, for: Google.Protobuf.Duration do
  def encode_message(msg, json_encode) do
    cond do
      msg.seconds < -315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "seconds is < -315_576_000_000")

      msg.seconds > 315_576_000_000 ->
        raise Protox.JsonEncodingError.new(msg, "seconds is > 315_576_000_000")

      msg.nanos < -999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "nanos is < -999_999_999")

      msg.nanos > 999_999_999 ->
        raise Protox.JsonEncodingError.new(msg, "nanos is > 999_999_999")

      true ->
        duration =
          Decimal.add(
            Decimal.new(msg.seconds),
            Decimal.div(Decimal.new(msg.nanos), Decimal.new(1_000_000_000))
          )

        json_encode.("#{Decimal.round(duration, 6)}s")
    end
  end
end
