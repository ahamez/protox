defmodule Protox.Message do
  @moduledoc false

  @type t() :: %__MODULE__{
          name: atom(),
          syntax: atom(),
          fields: list(Protox.Field.t()),
          # :file_options is first created from a message Google.Protobuf.FileOptions,
          # then it's transformed into a map, hence the two different types.
          file_options: struct() | %{atom() => any()}
        }

  @enforced_keys [:name, :syntax, :fields]
  @enforce_keys @enforced_keys
  defstruct @enforced_keys ++ [:file_options]
end
