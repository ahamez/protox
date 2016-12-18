defmodule Protox.Util do


  @primitive_fixed32 [
    :fixed32, :sfixed32, :float,
  ]

  @primitive_fixed64 [
    :fixed64, :sfixed64, :double,
  ]

  @primitive_fixed @primitive_fixed32 ++ @primitive_fixed64


  @primitive_varint [
    :int32, :uint32, :sint32, :int64, :uint64, :sint64, :bool
  ]

  @primitives @primitive_varint ++ @primitive_fixed

  defmacro is_primitive(type) do
    quote do: unquote(type) in unquote(@primitives)
  end


  defmacro is_primitive_varint(type) do
    quote do: unquote(type) in unquote(@primitive_varint)
  end


  defmacro is_primitive_fixed32(type) do
    quote do: unquote(type) in unquote(@primitive_fixed32)
  end


  defmacro is_primitive_fixed64(type) do
    quote do: unquote(type) in unquote(@primitive_fixed64)
  end


  defmacro is_primitive_fixed(type) do
    quote do: unquote(type) in unquote(@primitive_fixed)
  end


  defmacro is_delimited(type) do
    quote do
      unquote(type) == :string or unquote(type) == :bytes or\
      unquote(type) == Protox.Message
    end
  end

end
