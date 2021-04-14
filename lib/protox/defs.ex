defmodule Protox.Defs do
  @moduledoc false
  # Internal. Helpers to work with defs().

  # Extract oneofs and regroup them by parent field.
  def split_oneofs(fields) do
    {oneofs, fields} =
      Enum.split_with(fields, fn
        {_, _, _, {:oneof, _}, _} -> true
        _ -> false
      end)

    {
      oneofs
      |> Enum.group_by(fn {_, label, name, {:oneof, parent}, _} ->
        oneof_groupby(label, name, parent)
      end)
      |> Map.to_list(),
      fields
    }
  end

  def split_maps(fields) do
    Enum.split_with(fields, fn
      {_, _, _, :map, _} -> true
      _ -> false
    end)
  end

  defp oneof_groupby(:proto3_optional, name, _parent), do: name
  defp oneof_groupby(_, _, parent), do: parent
end
