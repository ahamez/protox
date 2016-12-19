defmodule Protox.Default do

  # alias Protox.{
  #   Message,
  # }

  def default(:bool)             , do: false
  def default(:int32)            , do: 0
  def default(:uint32)           , do: 0
  def default(:int64)            , do: 0
  def default(:uint64)           , do: 0
  def default(:sint32)           , do: 0
  def default(:sint64)           , do: 0
  def default(:fixed64)          , do: 0
  def default(:sfixed64)         , do: 0
  def default(:fixed32)          , do: 0
  def default(:sfixed32)         , do: 0
  def default(:double)           , do: 0
  def default(:float)            , do: 0
  def default(:string)           , do: ""
  def default(:bytes)            , do: <<>>
  # def default(%Message{})        , do: nil

end
