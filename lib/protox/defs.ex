defmodule Protox.Defs do
  @moduledoc false
  # Internal. Helpers to work with list of fields.

  alias Protox.{Field, OneOf}

  # Extract oneofs and regroup them by parent field.
  def split_oneofs(fields) do
    {all_oneofs, others} =
      Enum.split_with(fields, fn
        %Field{kind: %OneOf{}} -> true
        %Field{} -> false
      end)

    {proto3_optionals, oneofs} =
      Enum.split_with(all_oneofs, fn
        %Field{label: :proto3_optional} -> true
        %Field{} -> false
      end)

    grouped_oneofs = Enum.group_by(oneofs, &oneof_group_by/1)

    %{oneofs: grouped_oneofs, proto3_optionals: proto3_optionals, others: others}
  end

  @spec split_maps(list(Field.t())) :: {list(Field.t()), list(Field.t())}
  def split_maps(fields) do
    Enum.split_with(
      fields,
      fn field -> match?(%Field{kind: :map}, field) end
    )
  end

  defp oneof_group_by(field), do: field.kind.parent
end
