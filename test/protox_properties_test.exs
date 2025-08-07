defmodule Protox.PropertiesTest do
  use ExUnit.Case
  use ExUnitProperties

  property "Binary: ProtobufTestMessages.Proto3.TestAllTypesProto3" do
    check all {msg, encoded, encoded_bin, encoded_size, decoded} <-
              generate_binary(ProtobufTestMessages.Proto3.TestAllTypesProto3) do
      assert is_list(encoded)
      assert decoded == msg
      assert byte_size(encoded_bin) == encoded_size
    end
  end

  # -- Private

  defp generate_binary(mod) do
    bind(Protox.RandomInit.generate_fields(mod), fn fields ->
      msg = Protox.RandomInit.generate_struct(mod, fields)
      {:ok, encoded, encoded_size} = Protox.encode(msg)
      encoded_bin = IO.iodata_to_binary(encoded)
      decoded = Protox.decode!(encoded_bin, mod)

      constant({msg, encoded, encoded_bin, encoded_size, decoded})
    end)
  end
end
