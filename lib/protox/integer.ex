defmodule Protox.Integer do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @max_unsigned_32 4_294_967_295
      @max_unsigned_64 18_446_744_073_709_551_615

      @min_signed_32 -2_147_483_648
      @max_signed_32 2_147_483_647
      @min_signed_64 -9_223_372_036_854_775_808
      @max_signed_64 9_223_372_036_854_775_807
    end
  end
end
