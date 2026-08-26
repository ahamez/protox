defmodule Protox.PropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias ProtobufTestMessages.Proto3.TestAllTypesProto3

  property "Binary: ProtobufTestMessages.Proto3.TestAllTypesProto3" do
    check all(
            {msg, encoded, encoded_bin, encoded_size, decoded} <-
              generate_binary(TestAllTypesProto3)
          ) do
      assert is_list(encoded)
      assert byte_size(encoded_bin) == encoded_size
      assert decoded == msg
    end
  end

  # -- Private

  defp generate_binary(mod) do
    StreamData.bind(Protox.RandomInit.generate_fields_values(mod), fn fields ->
      msg = Protox.RandomInit.generate_struct(mod, fields)
      {:ok, encoded, encoded_size} = Protox.encode(msg)
      encoded_bin = IO.iodata_to_binary(encoded)
      decoded = Protox.decode!(encoded_bin, mod)

      StreamData.constant({msg, encoded, encoded_bin, encoded_size, decoded})
    end)
  end
end
