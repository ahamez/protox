defmodule Protox.PropertiesTest do
  use ExUnit.Case
  use PropCheck

  @moduletag :slow

  @tag :properties
  property "Upper" do
    forall {msg, encoded, encoded_bin, decoded} <- generate(Upper) do
      is_list(encoded) and is_binary(encoded_bin) and decoded == msg
    end
  end

  defp generate(mod) do
    let fields <- Protox.RandomInit.generate_fields(mod) do
      msg = Protox.RandomInit.generate_struct(mod, fields)
      encoded = Protox.encode!(msg)
      encoded_bin = :binary.list_to_bin(encoded)
      decoded = Protox.decode!(encoded_bin, mod)

      {msg, encoded, encoded_bin, decoded}
    end
  end
end
