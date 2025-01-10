defmodule Protox.Types do
  @moduledoc """
  This module describes the types that define a protobuf message.

  See https://developers.google.com/protocol-buffers/docs/encoding#structure.
  """

  @typedoc """
  Variable length integer.
  """
  @type wire_varint :: 0

  @typedoc """
  64 bits scalar.
  """
  @type wire_64bits :: 1

  @typedoc """
  Repeated field.
  """
  @type wire_delimited :: 2

  @typedoc """
  32 bits scalar.
  """
  @type wire_32bits :: 5

  @typedoc """
  The wire type of a field: it tells how a field is encoded (32 or 64 bits scalar, repeated or
  variable-length integer).
  """
  @type tag :: wire_varint() | wire_64bits() | wire_delimited() | wire_32bits()

  @typedoc """
  This type indicates how a field is encoded.
  """
  @type kind :: {:scalar, scalar_default_value()} | :packed | :unpacked | :map | {:oneof, atom()}

  @typedoc """
  All the possible types that can be used as a default value for a scalar.
  """
  @type scalar_default_value ::
          binary()
          | boolean()
          | integer()
          | float()
          | atom()
          | nil

  @typedoc """
  All types that can be used as a key in a map field.
  """
  @type map_key ::
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
  All the types that can be stored in a protobuf message.
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
          | {:enum, atom()}
          | {:message, atom()}
          | {map_key(), type()}

  @typedoc """
  This type gives more information on the field presence (if applicable).
  """
  @type label ::
          :none
          | :optional
          | :proto3_optional
          | :repeated
          | :required
          | nil
end
