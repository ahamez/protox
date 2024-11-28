defmodule Protox.Guards do
  @moduledoc false

  @integers_fixed32 [:fixed32, :sfixed32]
  @integers_fixed64 [:fixed64, :sfixed64]

  @primitives_fixed32 [:float | @integers_fixed32]
  @primitives_fixed64 [:double | @integers_fixed64]
  @primitives_fixed @primitives_fixed32 ++ @primitives_fixed64

  @primitives_varint32 [:int32, :uint32, :sint32]
  @primitives_varint64 [:int64, :uint64, :sint64]
  @primitives_varint @primitives_varint32 ++ @primitives_varint64 ++ [:bool]

  @primitives @primitives_varint ++ @primitives_fixed

  @integers32 @integers_fixed32 ++ @primitives_varint32
  @integers64 @integers_fixed64 ++ @primitives_varint64
  @integers @integers32 ++ @integers64

  @floats [:float, :double]

  defguard is_primitive(type) when type in @primitives
  defguard is_primitive_varint(type) when type in @primitives_varint
  defguard is_primitive_fixed32(type) when type in @primitives_fixed32
  defguard is_primitive_fixed64(type) when type in @primitives_fixed64

  defguard is_delimited(type) when type == :string or type == :bytes

  defguard is_protobuf_integer(type) when type in @integers
  defguard is_protobuf_float(type) when type in @floats
end
