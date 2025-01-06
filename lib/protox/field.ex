defmodule Protox.Field do
  @moduledoc """
  The definition of a protobuf field (e.g. tag, type, etc.).
  """

  @type t() :: %__MODULE__{
          tag: number(),
          label: Protox.Types.label(),
          name: atom(),
          kind: Protox.Types.kind(),
          type: Protox.Types.type()
        }

  @keys [:tag, :label, :name, :kind, :type]
  @enforce_keys @keys
  defstruct @keys

  @doc false
  @spec new!(keyword()) :: %__MODULE__{} | no_return()
  def new!(attrs) do
    tag = get_tag(attrs)
    label = get_label(attrs)
    name = Keyword.fetch!(attrs, :name)

    %__MODULE__{
      tag: tag,
      label: label,
      name: name,
      kind: Keyword.fetch!(attrs, :kind),
      type: Keyword.fetch!(attrs, :type)
    }
  end

  # -- Private

  defp get_tag(attrs) do
    tag = Keyword.fetch!(attrs, :tag)

    if tag == 0 do
      raise Protox.IllegalTagError.new()
    else
      tag
    end
  end

  @labels [:none, :optional, :proto3_optional, :repeated, :required, nil]
  defp get_label(attrs) do
    label = Keyword.get(attrs, :label, nil)

    if label in @labels do
      label
    else
      raise Protox.InvalidFieldAttribute.new(:label, @labels, label)
    end
  end
end
