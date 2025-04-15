defmodule Protox.Field do
  @moduledoc """
  The definition of a protobuf field (e.g. tag, type, etc.).
  """

  @type t() :: %__MODULE__{
          tag: number(),
          label: Protox.Types.label(),
          name: atom(),
          kind: Protox.Kind.t(),
          type: Protox.Types.type(),
          extender: nil | atom()
        }

  @enforce_keys [:tag, :label, :name, :kind, :type]
  defstruct @enforce_keys ++ [:extender]

  @doc false
  @spec new!(keyword()) :: %__MODULE__{} | no_return()
  def new!(attrs) do
    %__MODULE__{
      tag: fetch_tag!(attrs),
      label: fetch_label!(attrs),
      name: Keyword.fetch!(attrs, :name),
      kind: Keyword.fetch!(attrs, :kind),
      type: Keyword.fetch!(attrs, :type),
      extender: Keyword.get(attrs, :extender, nil)
    }
  end

  # -- Private

  defp fetch_tag!(attrs) do
    tag = Keyword.fetch!(attrs, :tag)

    if tag == 0 do
      raise Protox.IllegalTagError.new()
    else
      tag
    end
  end

  @labels [:none, :optional, :proto3_optional, :repeated, :required, nil]
  defp fetch_label!(attrs) do
    label = Keyword.get(attrs, :label, nil)

    if label in @labels do
      label
    else
      raise Protox.InvalidFieldAttributeError.new(:label, @labels, label)
    end
  end
end
