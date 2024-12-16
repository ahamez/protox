defmodule Protox.Google.Protobuf.Duration do
  @moduledoc false

  use Protox.Define,
    enums: [],
    messages: [
      %Protox.Message{
        name: Google.Protobuf.Duration,
        syntax: :proto3,
        fields: [
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :seconds,
            tag: 1,
            type: :int64
          ),
          Protox.Field.new!(
            kind: {:scalar, 0},
            label: :optional,
            name: :nanos,
            tag: 2,
            type: :int32
          )
        ]
      }
    ]
end

defimpl Protox.JsonMessageDecoder, for: Google.Protobuf.Duration do
  def decode_message(_initial_message, nil = _json) do
    nil
  end

  def decode_message(initial_message, json) do
    dec = get_decimal(json)

    {seconds, nanos} = get_seconds_nanos(dec)

    cond do
      seconds < -315_576_000_000 ->
        raise Protox.JsonDecodingError.new("#{seconds} is < -315_576_000_000")

      seconds > 315_576_000_000 ->
        raise Protox.JsonDecodingError.new("#{seconds} is > 315_576_000_000")

      true ->
        struct!(initial_message, seconds: seconds, nanos: nanos)
    end
  end

  # -- Private

  @dialyzer {:no_match, get_decimal: 1}
  defp get_decimal(json) do
    json_decimal =
      case String.split_at(json, -1) do
        {json_decimal, "s"} -> json_decimal
        _ -> raise Protox.JsonDecodingError.new("invalid duration format")
      end

    case Decimal.parse(json_decimal) do
      {dec, ""} -> dec
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
        raise Protox.JsonEncodingError.new("#{msg.__struct__}.seconds is < -315_576_000_000")

      msg.seconds > 315_576_000_000 ->
        raise Protox.JsonEncodingError.new("{msg.__struct__}.seconds is > 315_576_000_000")

      msg.nanos < -999_999_999 ->
        raise Protox.JsonEncodingError.new("{msg.__struct__}.nanos is < -999_999_999")

      msg.nanos > 999_999_999 ->
        raise Protox.JsonEncodingError.new("{msg.__struct__}.nanos is > 999_999_999")

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
            rem(msg.nanos, 1_000) == 0 -> 6
            true -> 9
          end

        json_encode.("#{Decimal.round(duration, digits)}s")
    end
  end
end
