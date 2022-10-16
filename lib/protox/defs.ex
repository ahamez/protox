defmodule Protox.Defs do
  @moduledoc false
  # Internal. Helpers to work with list of fields.

  alias Protox.Field

  # Extract oneofs and regroup them by parent field.
  def split_oneofs(fields) do
    {oneofs, others} =
      Enum.split_with(fields, fn
        %Field{kind: {:oneof, _}} -> true
        %Field{} -> false
      end)

    grouped_oneofs = Enum.group_by(oneofs, &oneof_group_by/1)

    %{oneofs: grouped_oneofs, others: others}
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
