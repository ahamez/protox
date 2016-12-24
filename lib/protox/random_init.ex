defmodule Protox.RandomInit do

  @moduledoc"""
  This module provides a way to randomly init a message. Useful for tests or benchmarks.
  """

  import Protox.Guards

  def gen(mod) do
    Enum.reduce(mod.defs(), struct(mod.__struct__),
      fn ({_, {name, kind, type}}, msg) ->
        case kind do
          {:oneof, _} -> msg # TODO.
          _           -> struct!(msg, [{name, value(kind, type)}])
        end
      end)
  end


  # -- Private


  # Recursively descend a message definition to randomly init fields.
  defp value({:normal, _}, {:enum, enum}) do
    enum.members() |> Map.new() |> Map.values() |> Enum.random()
  end
  defp value({:normal, _}, :bool) do
    :rand.uniform(2) == 1
  end
  defp value({:normal, _}, ty)
  when ty == :int32 or ty == :int64 or ty == :sint32 or ty == :sint64 or ty == :sfixed32
       or ty == :sfixed64
  do
    :rand.uniform(100) * sign()
  end
  defp value({:normal, _}, ty) when ty == :double or ty == :float do
    :rand.uniform(1000000) * :rand.uniform() * sign()
  end
  defp value({:normal, _}, ty) when is_primitive(ty) do
    :rand.uniform(1000000)
  end
  defp value({:normal, _}, :bytes) do
    Enum.reduce(1..:rand.uniform(10), <<>>, fn (b, acc) -> <<b, acc::binary>> end)
  end
  defp value({:normal, _}, :string) do
    if sign() == 1, do: "#{inspect make_ref()}", else: ""
  end
  defp value({:normal, _}, {:message, name}) do
    if :rand.uniform(2) == 1 do
      Protox.RandomInit.gen(name)
    else
      nil
    end
  end
  defp value({:repeated, _}, :bool) do
    for _ <- 1..:rand.uniform(10), do: value({:normal, nil}, :bool)
  end
  defp value({:repeated, _}, ty) when is_primitive(ty) do
    for _ <- 1..:rand.uniform(10), do: :rand.uniform(100)
  end
  defp value({:repeated, _}, e = {:enum, _}) do
    for _ <- 1..:rand.uniform(10), do: value({:normal, nil}, e)
  end
  defp value({:repeated, _}, m = {:message, _}) do
    Enum.reduce(
      1..:rand.uniform(10),
      [],
      fn (_ , acc) ->
        sub = value({:normal, nil}, m)
        if sub do
          [sub | acc]
        else
          acc
        end
      end
    )
  end
  defp value(:map, {key_type, value_type}) do
    Enum.reduce(
      1..:rand.uniform(10),
      %{},
      fn (_ , acc) ->
        key = value({:normal, nil}, key_type)
        value = value({:normal, nil}, value_type)
        if key && value do
          Map.put(acc, key, value)
        else
          acc
        end
      end
    )
  end

  # Get a random sign.
  defp sign() do
    if :rand.uniform(2) == 1, do: -1, else: 1
  end

end