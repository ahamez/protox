defmodule Protox.Guards do
  @moduledoc false
  # Internal. Provides macros to be used as guards when checking types is needed.

  @integers_fixed32 [:fixed32, :sfixed32]
  @integers_fixed64 [:fixed64, :sfixed64]

  @primitives_fixed32 @integers_fixed32 ++ [:float]
  @primitives_fixed64 @integers_fixed64 ++ [:double]
  @primitives_fixed @primitives_fixed32 ++ @primitives_fixed64

  @primitives_varint32 [:int32, :uint32, :sint32]
  @primitives_varint64 [:int64, :uint64, :sint64]
  @primitive_varint @primitives_varint32 ++ @primitives_varint64 ++ [:bool]

  @primitives @primitive_varint ++ @primitives_fixed

  @integers @integers_fixed32 ++ @integers_fixed64 ++ @primitives_varint32 ++ @primitives_varint64
  @floats [:float, :double]

  defmacro is_primitive(type) do
    quote do: unquote(type) in unquote(@primitives)
  end

  defmacro is_primitive_varint(type) do
    quote do: unquote(type) in unquote(@primitive_varint)
  end

  defmacro is_primitive_fixed32(type) do
    quote do: unquote(type) in unquote(@primitives_fixed32)
  end

  defmacro is_primitive_fixed64(type) do
    quote do: unquote(type) in unquote(@primitives_fixed64)
  end

  defmacro is_delimited(type) do
    quote do
      unquote(type) == :string or unquote(type) == :bytes or unquote(type) == Protox.Message
    end
  end

  defmacro is_protobuf_integer(type) do
    quote do
      unquote(type) in unquote(@integers)
    end
  end

  defmacro is_protobuf_float(type) do
    quote do
      unquote(type) in unquote(@floats)
    end
  end
end
