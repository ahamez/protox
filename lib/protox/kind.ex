defmodule Protox.Kind do
  @moduledoc """
  Defines the kind of a field.

  It can be one of the following:

  - `Protox.Scalar` - A [scalar](https://protobuf.dev/programming-guides/proto3/#scalar) value.
  - `:packed` - A [packed repeated](https://protobuf.dev/programming-guides/encoding/#packed) field.
  - `:unpacked` - An [unpacked repeated](https://protobuf.dev/programming-guides/encoding/#optional) field.
  - `:map` - A [map](https://protobuf.dev/programming-guides/encoding/#maps) field.
  - `Protox.OneOf` - A [oneof](https://protobuf.dev/programming-guides/encoding/#oneofs) field.
  """

  @type t() :: Protox.Scalar.t() | :packed | :unpacked | :map | Protox.OneOf.t()
end
