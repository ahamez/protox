defmodule Protox.PropertiesTest do
  use ExUnit.Case
  use PropCheck

  Code.require_file("test/support/messages.exs")
  Code.require_file("test/support/random_init.exs")

  @moduletag :slow

  @tag :properties
  property "Binary: Upper" do
    forall {msg, encoded, encoded_bin, decoded} <- generate_binary(Upper) do
      is_list(encoded) and is_binary(encoded_bin) and decoded == msg
    end
  end

  @tag :properties
  property "JSON: Sub" do
    # Use Sub as it doesn't contain any nestedd proto2 message
    forall {msg, encoded, decoded} <- generate_json(Sub) do
      is_list(encoded) and decoded == msg
    end
  end

  # -- Private

  defp generate_binary(mod) do
    let fields <- Protox.RandomInit.generate_fields(mod) do
      msg = Protox.RandomInit.generate_struct(mod, fields)
      encoded = Protox.encode!(msg)
      encoded_bin = :binary.list_to_bin(encoded)
      decoded = Protox.decode!(encoded_bin, mod)

      {msg, encoded, encoded_bin, decoded}
    end
  end

  defp generate_json(mod) do
    let fields <- Protox.RandomInit.generate_fields(mod) do
      msg = Protox.RandomInit.generate_struct(mod, fields)
      encoded = Protox.json_encode!(msg)
      decoded = Protox.json_decode!(encoded, mod)

      {msg, encoded, decoded}
    end
  end
end
