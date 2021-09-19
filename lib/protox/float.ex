defmodule Protox.Float do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      # IEEE 754-1985
      #
      # * 32 bits
      #   [0  - 22] -> fraction ( 23 bits )
      #   [23 - 30] -> exponent ( 8 bits  )
      #   [31 - 31] -> sign     ( 1 bit   )
      #
      # * 64 bits
      #   [0  - 51] -> fraction ( 52 bits )
      #   [52 - 62] -> exponent ( 11 bits )
      #   [63 - 63] -> sign     ( 1 bit   )
      #
      # * Positive and negative infinity
      #   sign     -> 0 for positive infinity, 1 for negative infinity.
      #   exponent -> all bits set to 1
      #   fraction -> all bits set to 0
      #
      # * NaN
      #   sign     -> 0 or 1
      #   exponent -> all bits set to 1
      #   fraction -> anything except all bits set to 0
      #
      # * Protobuf uses little-endian

      @positive_infinity_64 <<0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
      @negative_infinity_64 <<0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
      @nan_64 <<1::48, 0b1111::4, 1::4, 1::1, 0b1111111::7>>
      @min_double Protox.Float.min_double()
      @max_double Protox.Float.max_double()

      @positive_infinity_32 <<0, 0, 0x80, 0x7F>>
      @negative_infinity_32 <<0, 0, 0x80, 0xFF>>
      @nan_32 <<1::16, 1::1, 1::7, 1::1, 0b1111111::7>>
      @min_float Protox.Float.min_float()
      @max_float Protox.Float.max_float()
    end
  end

  def min_float() do
    <<value::float-big-32>> = <<0b11111111011111111111111111111111::32>>

    value
  end

  def max_float() do
    <<value::float-big-32>> = <<0b01111111011111111111111111111111::32>>

    value
  end

  def min_double() do
    <<value::float-big-64>> =
      <<0b1111111111101111111111111111111111111111111111111111111111111111::64>>

    value
  end

  def max_double() do
    <<value::float-big-64>> =
      <<0b0111111111101111111111111111111111111111111111111111111111111111::64>>

    value
  end
end
