defmodule Protox.Types do
  @moduledoc """
  This module describes types that define a protobuf message.

  See https://developers.google.com/protocol-buffers/docs/encoding#structure.
  """

  @typedoc """
  The wire type of a field: it tells how a field is encoded (scalar, repeated, etc.).
  """
  @type tag :: 0 | 1 | 2 | 5

  @typedoc """
  This type give more details on how a field is encoded.
  """
  @type kind :: {:default, any} | :packed | :unpacked | :map | {:oneof, atom}

  @typedoc """
  All types that can be used as a key in map field.
  """
  @type map_key_type ::
          :int32
          | :int64
          | :uint32
          | :uint64
          | :sint32
          | :sint64
          | :fixed32
          | :fixed64
          | :sfixed32
          | :sfixed64
          | :bool
          | :string

  @typedoc """
  All types that can be stored in a protobuf message.
  """
  @type type ::
          :fixed32
          | :sfixed32
          | :float
          | :fixed64
          | :sfixed64
          | :double
          | :int32
          | :uint32
          | :sint32
          | :int64
          | :uint64
          | :sint64
          | :bool
          | :string
          | :bytes
          | {:enum, atom}
          | {:message, atom}
          | {map_key_type, type}
end
