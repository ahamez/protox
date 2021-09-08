defmodule Protox.Defs do
  @moduledoc false
  # Internal. Helpers to work with defs().

  alias Protox.Field

  # Extract oneofs and regroup them by parent field.
  @spec split_oneofs(list(Field.t())) :: {list(Field.t()), list(Field.t())}
  def split_oneofs(fields) do
    {oneofs, fields} =
      Enum.split_with(fields, fn
        %Field{kind: {:oneof, _}} -> true
        %Field{} -> false
      end)

    grouped_oneofs =
      oneofs
      |> Enum.group_by(fn field -> oneof_group_by(field) end)
      |> Map.to_list()

    {grouped_oneofs, fields}
  end

  @spec split_maps(list(Field.t())) :: {list(Field.t()), list(Field.t())}
  def split_maps(fields) do
    Enum.split_with(
      fields,
      fn field -> match?(%Field{kind: :map}, field) end
    )
  end

  defp oneof_group_by(%Field{label: :proto3_optional, name: name}), do: name
  defp oneof_group_by(%Field{kind: {:oneof, parent}}), do: parent
end
