defmodule Protox.Benchmarks.Run do
  def decode({mod, bytes}), do: Protox.decode!(bytes, namespace(mod))
  def encode(msg), do: Protox.encode(msg)

  def decode_name(), do: "decode_protox"
  def decode_file_name(), do: "decode_protox.benchee"

  def encode_name(), do: "encode_protox"
  def encode_file_name(), do: "encode_protox.benchee"

  defp namespace(mod), do: Module.safe_concat([Protox, Benchmarks, mod])
end
