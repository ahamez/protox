defmodule Protox.PropertiesTest do
  use ExUnit.Case
  use PropCheck

  # @moduletag timeout: 60_000 * 5

  property "Binary: ProtobufTestMessages.Proto3.TestAllTypesProto3" do
    forall {msg, encoded, decoded} <-
             generate_binary(ProtobufTestMessages.Proto3.TestAllTypesProto3) do
      is_list(encoded) and decoded == msg
    end
  end

  # -- Private

  defp generate_binary(mod) do
    let fields <- Protox.RandomInit.generate_fields(mod) do
      msg = Protox.RandomInit.generate_struct(mod, fields)
      {encoded, _} = Protox.encode!(msg)
      decoded = encoded |> IO.iodata_to_binary() |> Protox.decode!(mod)

      {msg, encoded, decoded}
    end
  end
end
