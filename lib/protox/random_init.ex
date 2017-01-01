defmodule Protox.RandomInit do

  @moduledoc """
  Provides a way to randomly init a message. Useful for tests or benchmarks.
  """

  import Protox.Guards


  @doc """
  Generates a randomly initialized message using its definition. It's possible to
  give a seed as the second parameter to get reproducible results.

  """
  @spec generate(atom, nil | integer) :: struct
  def generate(mod, seed \\ nil) do
    if seed != nil do
      :rand.seed(:exs1024, {seed, seed, seed})
    end
    do_generate(mod)
  end


  # -- Private


  defp do_generate(mod) do
    Enum.reduce(mod.defs(), struct(mod.__struct__),
      fn ({_, {name, kind, type}}, msg) ->
        case kind do
          {:oneof, _} -> msg # TODO.
          _           -> struct!(msg, [{name, value(kind, type)}])
        end
      end)
  end


  # Recursively descend a message definition to randomly init fields.
  defp value({:default, _}, {:enum, enum}) do
    enum.constants() |> Map.new() |> Map.values() |> Enum.random()
  end
  defp value({:default, _}, :bool) do
    :rand.uniform(2) == 1
  end
  defp value({:default, _}, ty)
  when ty == :int32 or ty == :int64 or ty == :sint32 or ty == :sint64 or ty == :sfixed32
       or ty == :sfixed64
  do
    :rand.uniform(100) * sign()
  end
  defp value({:default, _}, ty) when ty == :double or ty == :float do
    :rand.uniform(1_000_000) * :rand.uniform() * sign()
  end
  defp value({:default, _}, ty) when is_primitive(ty) do
    :rand.uniform(1_000_000)
  end
  defp value({:default, _}, :bytes) do
    Enum.reduce(1..:rand.uniform(10), <<>>, fn (b, acc) -> <<b, acc::binary>> end)
  end
  defp value({:default, _}, :string) do
    if sign() == 1, do: "#{Protox.Util.random_string(:rand.uniform(100))}", else: ""
  end
  defp value({:default, _}, {:message, name}) do
    if :rand.uniform(2) == 1 do
      do_generate(name)
    else
      nil
    end
  end
  defp value(kind, :bool) when kind == :packed or kind == :unpacked do
    for _ <- 1..:rand.uniform(10), do: value({:default, nil}, :bool)
  end
  defp value(kind, ty) when is_primitive(ty) and (kind == :packed or kind == :unpacked) do
    for _ <- 1..:rand.uniform(10), do: :rand.uniform(100)
  end
  defp value(kind, e = {:enum, _}) when kind == :packed or kind == :unpacked do
    for _ <- 1..:rand.uniform(10), do: value({:default, nil}, e)
  end
  defp value(:unpacked, m = {:message, _}) do
    Enum.reduce(
      1..:rand.uniform(10),
      [],
      fn (_ , acc) ->
        sub = value({:default, nil}, m)
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
        key = value({:default, nil}, key_type)
        value = value({:default, nil}, value_type)
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
