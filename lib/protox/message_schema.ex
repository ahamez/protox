defmodule Protox.MessageSchema do
  @moduledoc """
  Represents the schema of a Protocol Buffers message once it has been processed by Protox.

  This struct contains all the necessary information to describe a message in a Protocol Buffers
  schema, including its name, syntax version, fields, and optional file-level options.

  ## Fields

  * `:name` - The atom representing the name of the message
  * `:syntax` - The Protocol Buffers syntax version (e.g., `:proto2` or `:proto3`)
  * `:fields` - A map of field names to their definitions (`Protox.Field.t()`)
  * `:file_options` - Optional file-level options, represented as a map if any.
  """
  @type t() :: %__MODULE__{
          name: atom(),
          syntax: atom(),
          fields: %{atom() => Protox.Field.t()},
          # :file_options, if set, is first created from a message Google.Protobuf.FileOptions,
          # then it's transformed into a map, hence the two different types.
          # In practice, end user will only see a map or nil.
          file_options: struct() | %{atom() => any()} | nil
        }

  @enforced_keys [:name, :syntax, :fields]
  @enforce_keys @enforced_keys
  defstruct @enforced_keys ++ [:file_options]

  @typedoc false
  @type compact_field() ::
          {atom(), number(), Protox.Types.label(), compact_kind(), Protox.Types.type()}
          | {atom(), number(), Protox.Types.label(), compact_kind(), Protox.Types.type(), atom()}

  @typedoc false
  @type compact_kind() :: {:scalar, any()} | :map | :packed | :unpacked | {:oneof, atom()}

  @doc false
  # Builds a schema from the compact field representation emitted by the code
  # generator, which is far smaller in source form than the escaped structs.
  # Called at compile time of the generated modules (the result is stored in a
  # module attribute); never on any runtime path.
  @spec expand!(atom(), atom(), [compact_field()], map() | nil) :: t()
  def expand!(name, syntax, compact_fields, file_options) do
    fields =
      Map.new(compact_fields, fn compact_field ->
        {field_name, tag, label, compact_kind, type} = five_first_elems(compact_field)

        field = %Protox.Field{
          tag: tag,
          label: label,
          name: field_name,
          kind: expand_kind(compact_kind),
          type: type,
          extender: extender(compact_field)
        }

        {field_name, field}
      end)

    %__MODULE__{name: name, syntax: syntax, fields: fields, file_options: file_options}
  end

  defp five_first_elems({name, tag, label, kind, type}), do: {name, tag, label, kind, type}
  defp five_first_elems({name, tag, label, kind, type, _extender}), do: {name, tag, label, kind, type}

  defp extender({_name, _tag, _label, _kind, _type, extender}), do: extender
  defp extender(_five_elems), do: nil

  defp expand_kind({:scalar, default_value}), do: %Protox.Scalar{default_value: default_value}
  defp expand_kind({:oneof, parent}), do: %Protox.OneOf{parent: parent}
  defp expand_kind(kind) when kind in [:map, :packed, :unpacked], do: kind

  @doc false
  # Backs the generated default/1 functions.
  @spec default(t(), atom()) ::
          {:ok, boolean() | integer() | String.t() | float() | nil}
          | {:error, :no_such_field | :no_default_value}
  def default(%__MODULE__{fields: fields}, field_name) do
    case fields do
      %{^field_name => %Protox.Field{kind: %Protox.Scalar{default_value: default_value}}} ->
        {:ok, default_value}

      %{^field_name => _field} ->
        {:error, :no_default_value}

      _no_such_field ->
        {:error, :no_such_field}
    end
  end
end
