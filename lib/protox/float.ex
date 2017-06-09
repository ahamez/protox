defmodule Protox.Float do

  @moduledoc false

  defmacro __using__(_) do
    quote do

      @positive_infinity_64 <<0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
      @negative_infinity_64 <<0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
      @nan_64               <<1::48, 0b1111::4, 1::4, 1::1, 0b1111111::7>>

      @positive_infinity_32 <<0, 0, 0x80, 0x7F>>
      @negative_infinity_32 <<0, 0, 0x80, 0xFF>>
      @nan_32               <<1::16, 1::1, 1::7, 1::1, 0b1111111::7>>

    end
  end

end
