defmodule Protox.Message do
  @moduledoc false

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
