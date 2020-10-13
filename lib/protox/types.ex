defmodule Protox.Types do
  @moduledoc """
  This module describes types that define a protobuf message.

  See https://developers.google.com/protocol-buffers/docs/encoding#structure.
  """
  @type tag :: 0 | 1 | 2 | 5
  @type kind :: {:default, any} | :packed | :unpacked | :map | {:oneof, atom}
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
