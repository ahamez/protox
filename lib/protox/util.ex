defmodule Protox.Util do

  defmacro is_primitive(type) do
    quote do
      unquote(type) == :int32 or unquote(type) == :int64 or\
      unquote(type) == :uint32 or unquote(type) == :uint64 or\
      unquote(type) == :sint32 or unquote(type) == :sint64 or\
      unquote(type) == :bool or unquote(type) == :float or\
      unquote(type) == :fixed32 or unquote(type) == :sfixed32 or\
      unquote(type) == :double or unquote(type) == :fixed64 or\
      unquote(type) == :sfixed64

    end
  end


  defmacro is_primitive_varint(type) do
    quote do
      unquote(type) == :int32 or unquote(type) == :int64 or\
      unquote(type) == :uint32 or unquote(type) == :uint64 or\
      unquote(type) == :sint32 or unquote(type) == :sint64 or\
      unquote(type) == :bool or unquote(type)
    end
  end


  defmacro is_primitive_fixed32(type) do
    quote do
      unquote(type) == :float or unquote(type) == :fixed32 or unquote(type) == :sfixed32
    end
  end


  defmacro is_primitive_fixed64(type) do
    quote do
      unquote(type) == :fixed64 or unquote(type) == :sfixed64 or unquote(type) == :double
    end
  end


  defmacro is_primitive_fixed(type) do
    quote do
      # TODO. How can we factorize this?
      unquote(type) == :fixed64 or unquote(type) == :sfixed64 or\
      unquote(type) == :double or unquote(type) == :float or\
      unquote(type) == :fixed32 or unquote(type) == :sfixed32
    end
  end


  defmacro is_delimited(type) do
    quote do
      unquote(type) == :string or unquote(type) == :bytes or\
      unquote(type) == Protox.Message
    end
  end

end
