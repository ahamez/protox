defmodule Protox.Integer do
  defmacro __using__(_) do
    quote do
      @max_unsigned_32 Protox.Integer.max_unsigned_32()
      @max_unsigned_64 Protox.Integer.max_unsigned_64()
    end
  end

  def max_unsigned_32() do
    <<value::little-32>> = <<0b11111111111111111111111111111111::32>>

    value
  end

  def max_unsigned_64() do
    <<value::little-64>> =
      <<0b1111111111111111111111111111111111111111111111111111111111111111::64>>

    value
  end
end
