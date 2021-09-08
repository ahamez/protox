defmodule Protox.WireTypes do
  @moduledoc false
  # Internal.
  # Describe messages fields types.
  # See https://developers.google.com/protocol-buffers/docs/encoding#structure.

  defmacro __using__(_) do
    quote do
      @wire_varint 0
      @wire_64bits 1
      @wire_delimited 2
      @wire_32bits 5
    end
  end
end
