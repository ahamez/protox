defmodule Protox.Field do
  @moduledoc """
  The definition of a protobuf field (e.g. tag, type, etc.).
  """

  @type t() :: %__MODULE__{
          tag: number(),
          label: atom(),
          name: atom(),
          kind: atom() | {:default, any()} | {:oneof, atom()},
          type: atom() | {atom(), atom()} | {atom(), {:enum | :message, atom()}},
          json_name: binary()
        }

  @keys [:tag, :label, :name, :kind, :type, :json_name]
  @enforce_keys @keys
  defstruct @keys

  @labels [:none, :optional, :proto3_optional, :repeated, :required, nil]

  @spec new(keyword()) :: %__MODULE__{} | no_return()
  def new(attrs) do
    tag = get_tag(attrs)
    label = get_label(attrs)
    name = Keyword.fetch!(attrs, :name)

    %__MODULE__{
      tag: tag,
      label: label,
      name: name,
      kind: Keyword.fetch!(attrs, :kind),
      type: Keyword.fetch!(attrs, :type),
      json_name: make_json_name(name, Keyword.get(attrs, :json_name, &lower_camel_case/1))
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

  defp get_label(attrs) do
    label = Keyword.get(attrs, :label, nil)

    if label in @labels do
      label
    else
      raise Protox.InvalidFieldAttribute.new(:label, @labels, label)
    end
  end

  defp make_json_name(name, fun) when is_function(fun) do
    fun.(name)
  end

  defp make_json_name(_name, string) when is_binary(string) do
    string
  end

  defp lower_camel_case(atom) do
    <<first, rest::binary>> = atom |> Atom.to_string() |> Macro.camelize()

    <<String.downcase(<<first>>, :ascii)::binary, rest::binary>>
  end
end
