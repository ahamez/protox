defmodule Protox.MessageSchema do
  @moduledoc """
  Represents the schema of a Protocol Buffers message once it has been processed by Protox.

  This struct contains all the necessary information to describe a message in a Protocol Buffers
  schema, including its name, syntax version, fields, and optional file-level options.

  ## Fields

  * `:name` - The atom representing the name of the message
  * `:syntax` - The Protocol Buffers syntax version (e.g., `:proto2` or `:proto3`)
  * `:fields` - A map of field names to their definitions (`Protox.Field.t()`)
  * `:file_options` - Optional file-level options, represented as a map if any.
  """
  @type t() :: %__MODULE__{
          name: atom(),
          syntax: atom(),
          fields: %{atom() => Protox.Field.t()},
          # :file_options, if set, is first created from a message Google.Protobuf.FileOptions,
          # then it's transformed into a map, hence the two different types.
          # In practice, end user will only see a map or nil.
          file_options: struct() | %{atom() => any()} | nil
        }

  @enforced_keys [:name, :syntax, :fields]
  @enforce_keys @enforced_keys
  defstruct @enforced_keys ++ [:file_options]
end
