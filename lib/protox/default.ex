defmodule Protox.Default do
  @moduledoc """
  Default values of Protocol Buffers types.

  Note that generated structs contain a default/1 function to return the default
  value of a field using its name.
  """

  @doc """
  Returns the default value of a Protocol Buffer type specified with an atom.

  ## Examples
      iex> Protox.Default.default(:bool)
      false

      iex> Protox.Default.default(:string)
      ""
  """
  @spec default(atom | {atom, atom}) :: false | integer | float | binary | nil | atom
  def default(:bool), do: false
  def default(:int32), do: 0
  def default(:uint32), do: 0
  def default(:int64), do: 0
  def default(:uint64), do: 0
  def default(:sint32), do: 0
  def default(:sint64), do: 0
  def default(:fixed64), do: 0
  def default(:sfixed64), do: 0
  def default(:fixed32), do: 0
  def default(:sfixed32), do: 0
  def default(:double), do: 0.0
  def default(:float), do: 0.0
  def default(:string), do: ""
  def default(:bytes), do: <<>>
  def default({:enum, e}), do: e.default()
  def default({:message, _}), do: nil
  def default(:group), do: nil
end
