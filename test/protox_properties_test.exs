defmodule Protox.PropertiesTest do
  use ExUnit.Case
  use PropCheck

  property "Binary: ProtobufTestMessages.Proto3.TestAllTypesProto3" do
    forall {msg, encoded, encoded_bin, encoded_size, decoded} <-
             generate_binary(ProtobufTestMessages.Proto3.TestAllTypesProto3) do
      is_list(encoded) and decoded == msg and byte_size(encoded_bin) == encoded_size
    end
  end

  # -- Private

  defp generate_binary(mod) do
    let fields <- Protox.RandomInit.generate_fields(mod) do
      msg = Protox.RandomInit.generate_struct(mod, fields)
      {:ok, encoded, encoded_size} = Protox.encode(msg)
      encoded_bin = encoded |> IO.iodata_to_binary()
      decoded = encoded_bin |> Protox.decode!(mod)

      {msg, encoded, encoded_bin, encoded_size, decoded}
    end
  end
end
