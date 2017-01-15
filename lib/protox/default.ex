defmodule Protox.Default do

  @moduledoc"""
  Default values of Protocol Buffers types. For protobuf2, it's useful to
  get the default values which have been set to `nil`, that is which were not
  present on the wire.
  """

  @doc"""
  Returns the default value of a Protocol Buffer type specified with an atom.
  """
  @spec default(atom) :: false | 0 | binary | nil | atom
  def default(:bool)        , do: false
  def default(:int32)       , do: 0
  def default(:uint32)      , do: 0
  def default(:int64)       , do: 0
  def default(:uint64)      , do: 0
  def default(:sint32)      , do: 0
  def default(:sint64)      , do: 0
  def default(:fixed64)     , do: 0
  def default(:sfixed64)    , do: 0
  def default(:fixed32)     , do: 0
  def default(:sfixed32)    , do: 0
  def default(:double)      , do: 0
  def default(:float)       , do: 0
  def default(:string)      , do: ""
  def default(:bytes)       , do: <<>>
  def default({:enum, e})   , do: e.default()
  def default({:message, _}), do: nil

end
